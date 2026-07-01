export interface AIPersona {
  name: string;
  role: string;
  tone: 'professional' | 'friendly' | 'formal' | 'casual' | 'empathetic';
  language?: string;
  knowledge_base?: string[];
  tools?: ('calendar' | 'whatsapp' | 'email' | 'web_search')[];
}
