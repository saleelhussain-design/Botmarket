export interface AIPersona {
  id: number;
  name: string;
  role: string;
  tone: 'professional' | 'friendly' | 'formal' | 'casual' | 'empathetic';
  language?: string;
  knowledge_base?: string[];
  tools?: ('calendar' | 'whatsapp' | 'email' | 'web_search')[];
  is_template?: boolean;
  vapi_assistant_id?: string;
  calendar_config?: any;
  whatsapp_config?: any;
  tenant_id: number;
}
