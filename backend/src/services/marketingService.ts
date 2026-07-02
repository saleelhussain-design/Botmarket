import Persona from '../models/Persona';

export interface ContentGenerationParams {
  personaId: number;
  productName: string;
  targetAudience: string;
  platform: 'linkedin' | 'instagram' | 'email' | 'whatsapp';
}

export interface Lead {
  name: string;
  address: string;
  phone: string;
  website?: string;
  score: number; // Added qualification score
}

export class MarketingService {
  
  // Internal method to build a high-fidelity prompt for an LLM
  private buildMarketingPrompt(persona: Persona, params: ContentGenerationParams): string {
    const { productName, targetAudience, platform } = params;
    
    return `
      ACT AS: ${persona.role}
      TONE: ${persona.tone}
      AGENT NAME: ${persona.name}
      
      GOAL: Generate a high-converting ${platform} post for ${productName}.
      TARGET AUDIENCE: ${targetAudience}
      
      REQUIREMENTS:
      1. Use the ${persona.tone} tone consistently.
      2. Highlight the benefits of having a ${persona.role} to automate their business.
      3. Include a strong Call to Action (CTA).
      4. Format the output specifically for ${platform} (e.g., hashtags for Instagram, professional structure for LinkedIn).
      
      OUTPUT FORMAT:
      - Hook: [Catchy opening]
      - Value Proposition: [How it helps the audience]
      - CTA: [What they should do next]
    `;
  }

  async generateMarketingCopy(params: ContentGenerationParams): Promise<string> {
    const persona = await Persona.findByPk(params.personaId);
    if (!persona) throw new Error('Persona not found');

    const prompt = this.buildMarketingPrompt(persona, params);
    
    // SIMULATION: In production, this calls the LLM API with the prompt
    console.log(`[LLM Request] Sending Prompt:\n${prompt}`);
    
    return `[AI GENERATED CONTENT - ${params.platform.toUpperCase()}]\n\n` +
           `✨ ${persona.name} is here to revolutionize your ${params.productName}!\n\n` +
           `Stop wasting hours on manual tasks. As a ${persona.role}, I handle everything with a ${persona.tone} approach, ensuring your ${params.targetAudience} get the best experience possible.\n\n` +
           `👉 Book a demo now and let's scale your business! #AIWorkforce #BotMarket`;
  }

  async scrapeBusinessLeads(source: string, query: string): Promise<Lead[]> {
    console.log(`Scraping ${query} from ${source}...`);
    
    // Simulating lead generation with a "Qualification Score" (AI-driven)
    return [
      { name: `${query} Elite 1`, address: '123 Main St, Dubai', phone: '+971-50-0001', website: 'https://elite1.ae', score: 95 },
      { name: `${query} Pro 2`, address: '456 Sheikh Zayed Rd, Dubai', phone: '+971-50-0002', website: 'https://pro2.ae', score: 82 },
      { name: `${query} Prime 3`, address: '789 Jumeirah, Dubai', phone: '+971-50-0003', website: 'https://prime3.ae', score: 68 },
    ];
  }
}

export const marketingService = new MarketingService();
