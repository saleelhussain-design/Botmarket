import { DataTypes, Model } from 'sequelize';
import sequelize from '../config/database';

class Persona extends Model {
  public id!: number;
  public tenant_id!: number;
  public name!: string;
  public role!: string;
  public tone!: string;
  public language?: string;
  public knowledge_base?: any[];
  public tools?: string[];
  public is_template?: boolean;
  public vapi_assistant_id?: string;
  public calendar_config?: any;
  public whatsapp_config?: any;
}

Persona.init({
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  tenant_id: { type: DataTypes.INTEGER, allowNull: false },
  name: { type: DataTypes.STRING, allowNull: false },
  role: { type: DataTypes.STRING, allowNull: false },
  tone: { type: DataTypes.STRING, allowNull: false },
  language: { type: DataTypes.STRING },
  knowledge_base: { type: DataTypes.JSON },
  tools: { type: DataTypes.JSON },
  is_template: { type: DataTypes.BOOLEAN, defaultValue: false },
  vapi_assistant_id: { type: DataTypes.STRING },
  calendar_config: { type: DataTypes.JSON },
  whatsapp_config: { type: DataTypes.JSON },
}, { sequelize, modelName: 'persona' });

export default Persona;

