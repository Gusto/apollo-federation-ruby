import globals from "globals";

export default [{
    languageOptions: {
        globals: {
            ...globals.jest,
        },
    },
}];