import 'dotenv/config';
import fs from 'fs/promises';
import path from 'path';
import crypto from 'crypto';
import { Document } from '@langchain/core/documents';
import { RecursiveCharacterTextSplitter } from '@langchain/textsplitters';
import { OpenAIEmbeddings } from '@langchain/openai';
import { PGVectorStore } from '@langchain/community/vectorstores/pgvector';
import { query } from '../db/index.js';

function mustGetEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Variável de ambiente ausente: ${name}`);
  return value;
}

function normalize(value: string): string {
  return value
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
    .slice(0, 40) || 'x';
}

function stableIdForDoc(doc: Document): string {
  const source = normalize(doc.metadata?.source || 'unknown');
  const section = normalize(doc.metadata?.section || 'geral');
  const chunk = Number.isFinite(doc.metadata?.chunk) ? String(doc.metadata.chunk) : '0';
  const hash = crypto
    .createHash('sha1')
    .update((doc.pageContent || '').toString(), 'utf8')
    .digest('hex')
    .slice(0, 16);
  return `${source}:${section}:${chunk}:${hash}`;
}

function splitByHeadings(markdownText: string): Array<{ title: string; content: string }> {
  const text = (markdownText || '').toString().replace(/\r\n/g, '\n');
  const lines = text.split('\n');
  const sections: Array<{ title: string; content: string }> = [];
  let currentTitle = 'Geral';
  let current: string[] = [];

  function pushSection(): void {
    const content = current.join('\n').trim();
    if (content) sections.push({ title: currentTitle, content });
    current = [];
  }

  for (const line of lines) {
    const match = line.match(/^#{1,3}\s+(.+)\s*$/);
    if (match) {
      const [, title] = match;
      if (!title) continue;
      pushSection();
      currentTitle = title.trim();
      current.push(line);
      continue;
    }
    current.push(line);
  }
  pushSection();

  if (sections.length === 0) return [{ title: 'Geral', content: text.trim() }];
  return sections;
}

async function listKnowledgeFiles(rootDir: string): Promise<string[]> {
  const files: string[] = [];

  async function walk(dir: string): Promise<void> {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        await walk(fullPath);
        continue;
      }
      if (entry.isFile() && /\.(md|txt)$/i.test(entry.name)) {
        files.push(fullPath);
      }
    }
  }

  await walk(rootDir);
  return files;
}

async function wipeCollection(collectionName: string): Promise<void> {
  await query(
    `DELETE FROM langchain_pg_embedding
     WHERE collection_id = (SELECT id FROM langchain_pg_collection WHERE name = $1);`,
    [collectionName],
  );
  await query(
    `DELETE FROM langchain_pg_collection WHERE name = $1;`,
    [collectionName],
  );
}

async function populateVectorStore(): Promise<void> {
  console.log('Iniciando ingestão do RAG...');

  const apiKey = mustGetEnv('OPENAI_API_KEY');
  mustGetEnv('DATABASE_URL');

  const knowledgeDir = process.env.RAG_KNOWLEDGE_DIR || 'knowledge';
  const collectionName = process.env.RAG_COLLECTION || 'driveconnect';

  const root = path.isAbsolute(knowledgeDir)
    ? knowledgeDir
    : path.join(process.cwd(), knowledgeDir);

  const files = await listKnowledgeFiles(root);
  if (files.length === 0) {
    console.warn(`Nenhum arquivo .md/.txt encontrado em ${root}`);
    return;
  }

  const shouldWipe =
    (process.env.RAG_WIPE_BEFORE_INGEST || '0') === '1' ||
    process.argv.includes('--wipe');

  if (shouldWipe) {
    console.log(`Limpando coleção ${collectionName}...`);
    await wipeCollection(collectionName);
  }

  const baseDocs: Document[] = [];
  for (const filePath of files) {
    const content = await fs.readFile(filePath, 'utf8');
    const rel = path.relative(root, filePath);
    const sections = splitByHeadings(content);
    for (const section of sections) {
      baseDocs.push(
        new Document({
          pageContent: section.content,
          metadata: { source: rel, section: section.title },
        }),
      );
    }
  }

  const textSplitter = new RecursiveCharacterTextSplitter({
    chunkSize: Number.parseInt(process.env.RAG_CHUNK_SIZE || '800', 10),
    chunkOverlap: Number.parseInt(process.env.RAG_CHUNK_OVERLAP || '160', 10),
  });

  const docs: Document[] = await textSplitter.splitDocuments(baseDocs);
  docs.forEach((doc: Document, i: number) => {
    doc.metadata = {
      ...(doc.metadata || {}),
      chunk: i,
      stable_id: stableIdForDoc(doc),
    };
  });

  const embeddings = new OpenAIEmbeddings({
    modelName: process.env.OPENAI_EMBED_MODEL || 'text-embedding-3-small',
    openAIApiKey: apiKey,
  });

  const store = await PGVectorStore.initialize(embeddings, {
    postgresConnectionOptions: {
      connectionString: process.env.DATABASE_URL,
    },
    tableName: process.env.RAG_PG_TABLE || 'langchain_pg_embedding',
    collectionTableName: process.env.RAG_COLLECTION_TABLE || 'langchain_pg_collection',
    collectionName,
    columns: {
      contentColumnName: process.env.RAG_CONTENT_COLUMN || 'document',
      metadataColumnName: process.env.RAG_METADATA_COLUMN || 'metadata',
      vectorColumnName: process.env.RAG_VECTOR_COLUMN || 'embedding',
      idColumnName: process.env.RAG_ID_COLUMN || 'id',
    },
  });

  await store.addDocuments(docs);

  console.log(`Ingestão concluída. ${docs.length} chunks enviados para ${collectionName}.`);
}

populateVectorStore().catch((err) => {
  console.error('Erro durante a ingestão do RAG:', err);
  process.exitCode = 1;
});
