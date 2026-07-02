// /home/saleel/botmarket/backend/src/models/Tenant.ts
import { DataTypes, Model } from 'sequelize';
import sequelize from '../config/database';

class Tenant extends Model {
  public id!: number;
  public name!: string;
  public domain!: string;
  public apiKey!: string;
  public createdAt!: Date;
  public updatedAt!: Date;
}

Tenant.init({
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  name: { type: DataTypes.STRING, allowNull: false },
  domain: { type: DataTypes.STRING, unique: true },
  apiKey: { type: DataTypes.STRING, unique: true },
}, { sequelize, modelName: 'tenant' });

export default Tenant;
