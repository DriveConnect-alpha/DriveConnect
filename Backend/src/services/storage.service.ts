import { IncomingMessage } from 'http';
import formidable from 'formidable';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

const CARROS_DIR = path.join(process.cwd(), 'uploads', 'carros');
const PERFIL_DIR = path.join(process.cwd(), 'uploads', 'perfil');
const EXTENSOES_IMAGEM_VALIDAS = new Set([
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
    '.heif',
]);

// Garante que os diretórios existam
[CARROS_DIR, PERFIL_DIR].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

export async function processarUpload(req: IncomingMessage, subdiretorio: 'carros' | 'perfil' = 'carros'): Promise<{ campos: Record<string, any>, caminhosImagens: string[], caminhoImagem: string | null }> {
    const uploadDir = subdiretorio === 'perfil' ? PERFIL_DIR : CARROS_DIR;
    const ehImagemValida = (part: any): boolean => {
        const mimetype = String(part?.mimetype ?? '').toLowerCase();
        if (mimetype.includes('image/')) {
            return true;
        }

        const originalFilename = String(part?.originalFilename ?? '').toLowerCase();
        const extensao = path.extname(originalFilename);
        return EXTENSOES_IMAGEM_VALIDAS.has(extensao);
    };

    const form = formidable({
        uploadDir,
        keepExtensions: true,
        maxFileSize: 5 * 1024 * 1024, // 5MB (compatível com testes e uso padrão)
        multiples: false, // Veículo aceita apenas uma imagem
        filename: (name: string, ext: string, part: any) => {
            return `${uuidv4()}${ext}`;
        },
        filter: (part: any) => ehImagemValida(part)
    });

    return new Promise((resolve, reject) => {
        form.parse(req, (err: any, fields: any, files: any) => {
            if (err) {
                return reject(new Error('Erro ao processar arquivo: ' + err.message));
            }

            const campos: Record<string, any> = {};
            for (const key in fields) {
                const val = fields[key];
                campos[key] = Array.isArray(val) ? val[0] : val;
            }

            const arquivosEncontrados: string[] = [];
            const todasEntradas = Object.values(files ?? {});

            for (const entrada of todasEntradas) {
                const fileArray = Array.isArray(entrada) ? entrada : [entrada];
                for (const file of fileArray) {
                    if (file?.newFilename) {
                        arquivosEncontrados.push(file.newFilename);
                    }
                }
            }

            if (arquivosEncontrados.length > 1) {
                for (const filename of arquivosEncontrados) {
                    try {
                        fs.unlinkSync(path.join(uploadDir, filename));
                    } catch {
                        // noop
                    }
                }
                return reject(new Error('Apenas uma imagem é permitida.'));
            }

            const caminhoImagem: string | null = arquivosEncontrados.length > 0
                ? (arquivosEncontrados[0] ?? null)
                : null;
            const caminhosImagens = caminhoImagem ? [caminhoImagem] : [];
            resolve({ campos, caminhosImagens, caminhoImagem });
        });
    });
}

// Ler arquivo de forma segura
export function lerArquivoSeguro(filename: string, subdiretorio: 'carros' | 'perfil' = 'carros'): fs.ReadStream {
    const baseDir = subdiretorio === 'perfil' ? PERFIL_DIR : CARROS_DIR;
    const filepath = path.join(baseDir, filename);

    // Evita path traversal: verifica se o caminho resolvido continua dentro da pasta
    if (!filepath.startsWith(baseDir)) {
        throw new Error('Acesso negado.');
    }

    if (!fs.existsSync(filepath)) {
        throw new Error('Arquivo não encontrado.');
    }

    return fs.createReadStream(filepath);
}
