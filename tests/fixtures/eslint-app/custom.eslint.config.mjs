export default [
  {
    languageOptions: {
      globals: {
        console: "readonly",
        process: "readonly",
        require: "readonly",
        module: "readonly",
        exports: "readonly",
        __dirname: "readonly",
        __filename: "readonly"
      }
    },
    rules: {
      "no-console": "off",
      "no-unused-vars": "warn"
    }
  }
];
