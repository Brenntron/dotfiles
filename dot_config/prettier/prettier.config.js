export default {
  printWidth: 100,
  tabWidth: 2,
  useTabs: false,
  semi: true,
  singleQuote: true,
  trailingComma: "all",
  bracketSpacing: true,
  arrowParens: "always",

  overrides: [
    {
      files: ["*.yaml", "*.yml"],
      options: {
        printWidth: 120,
        singleQuote: false,
        proseWrap: "preserve",
      },
    },
  ],
};
