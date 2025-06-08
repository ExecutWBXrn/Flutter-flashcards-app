module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", { "allowTemplateLiterals": true }],
    "indent": ["error", 2],
    "max-len": ["error", { "code": 100, "ignoreComments": true, "ignoreUrls": true }],
    "require-jsdoc": "off",
    "valid-jsdoc": "off",
    "comma-dangle": ["error", "always-multiline"],
    "eol-last": ["error", "always"],
    "no-multiple-empty-lines": ["error", { "max": 1, "maxEOF": 0, "maxBOF": 0 }],
    "object-curly-spacing": ["error", "always"],
    "arrow-parens": ["error", "as-needed"],
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
