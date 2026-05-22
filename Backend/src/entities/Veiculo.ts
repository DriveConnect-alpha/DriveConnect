export interface Veiculo {
    id?: string;
    modelo_id: number;
    filial_id: string;
    placa: string;
    ano: number;
    cor?: string | null;
    status: 'DISPONIVEL' | 'ALUGADO' | 'MANUTENCAO';
    imagem_url?: string | null;
    preco_diaria?: number | null;
    criado_em?: Date;
    deletado_em?: Date | null;
}
