import Ajv from 'ajv';
import personaSchema from '../schemas/persona.schema.json';

const ajv = new Ajv();
const validate = ajv.compile(personaSchema);

export const validatePersona = (data: any) => {
  const valid = validate(data);
  if (!valid) {
    return {
      isValid: false,
      errors: validate.errors,
    };
  }
  return { isValid: true, errors: null };
};
