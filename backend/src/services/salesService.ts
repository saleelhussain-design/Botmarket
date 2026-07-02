import Persona from '../models/Persona';

export interface PrototypeParams {
  leadName: string;
  businessName: string;
  industry: string;
  targetGoal: string;
}

export interface PrototypeResult {
  prototypeId: number;
  previewUrl: string;
  personaSummary: string;
}

export class SalesService {
  
  /**
   * Creates a "Prototype Agent" based on a lead's specific business details.
   * This is used to close sales by showing the lead a working demo of their own future bot.
   */
  async generatePrototype(params: PrototypeParams): Promise<PrototypeResult> {
    const { leadName, businessName, industry, targetGoal } = params;

    // 1. Create a temporary "Demo Persona" in the database
    const prototypePersona = await Persona.create({
      name: `${businessName} Demo Bot`,
      role: `Lead Generator for ${industry}`,
      tone: 'persuasive',
      tenant_id: 0, // System tenant for prototypes
      is_template: true,
      knowledge_base: [
        `Welcome to ${businessName}. I am your AI assistant created specifically for ${leadName}.`,
        `Our goal is to ${targetGoal} for all ${industry} clients.`,
        `I can handle bookings, answer FAQs, and qualify leads automatically.`
      ],
    });

    // 2. Generate a unique preview URL (Simulated)
    // In production, this would link to a specific chat widget instance
    const previewUrl = `http://botmarket.me/demo/bot_${prototypePersona.id}`;

    return {
      prototypeId: prototypePersona.id,
      previewUrl: previewUrl,
      personaSummary: `${prototypePersona.name} is now ready to show ${leadName} how we can automate their ${industry} business.`
    };
  }

  async calculateROI(monthlyCalls: number, averageTicketValue: number): Promise<{ savings: number; efficiencyGain: string }> {
    const costPerHumanReceptionist = 2500; // Monthly average
    const aiCost = 200; // Monthly per agent
    
    const savings = costPerHumanReceptionist - aiCost;
    const efficiencyGain = `${(monthlyCalls / 10).toFixed(0)} hours saved per month`;

    return { savings, efficiencyGain };
  }
}

export const salesService = new SalesService();
