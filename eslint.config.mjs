import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [
  {
    ignores: ["**/vendor/"]
  },
  {
    files: ["**/*.js"],
    languageOptions: {
      globals: {
        // For Node.js
        module: true,
        require: true,
        console: true,
        setTimeout: true,
        clearTimeout: true,

        // For Jest
        beforeAll: true,
        afterAll: true,
        it: true,
        expect: true,
        describe: true
      }
    },
  },
  ...compat.extends("eslint:recommended")
];
