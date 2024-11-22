module.exports = {
    env: {
        es2022: true,
        node: true,
    },
    extends: ['eslint:recommended', 'prettier', 'plugin:security/recommended'],
    parser: '@typescript-eslint/parser',
    parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
    },
    plugins: ['@typescript-eslint'],
    rules: {},
}