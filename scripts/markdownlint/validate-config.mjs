import { existsSync, readFileSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [cliEntrypointArg, projectRootArg] = process.argv.slice(2);

if (!cliEntrypointArg || !projectRootArg) {
    console.error("Usage: validate-config.mjs <cli-entrypoint> <project-root>");
    process.exit(2);
}

const cliEntrypoint = resolve(cliEntrypointArg);
const projectRoot = resolve(projectRootArg);

const supportedConfigFile = ".markdownlint-cli2.yaml";

const fullConfigFiles = [".markdownlint-cli2.jsonc", ".markdownlint-cli2.yaml", ".markdownlint-cli2.cjs", ".markdownlint-cli2.mjs"];

function report(result, exitCode) {
    process.stdout.write(`${JSON.stringify(result)}\n`);
    process.exitCode = exitCode;
}

function isMapping(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

async function main() {
    if (!existsSync(cliEntrypoint)) {
        throw new Error(`markdownlint-cli2 entrypoint not found: ${cliEntrypoint}`);
    }

    if (!existsSync(projectRoot) || !statSync(projectRoot).isDirectory()) {
        throw new Error(`Project root is not a directory: ${projectRoot}`);
    }

    const configFiles = fullConfigFiles.map((name) => ({
        name,
        path: join(projectRoot, name),
    }));

    const selected = configFiles.find(({ path }) => existsSync(path));

    if (!selected) {
        report(
            {
                valid: true,
                configPath: null,
                message: "No project-level CLI configuration found.",
            },
            0,
        );
        return;
    }

    if (selected.name !== supportedConfigFile) {
        report(
            {
                valid: false,
                configPath: selected.path,
                errors: [`Unsupported project configuration format: ${selected.name}.`, `Use ${supportedConfigFile} for project-level rule overrides.`],
            },
            1,
        );
        return;
    }

    if (!statSync(selected.path).isFile()) {
        throw new Error(`Project configuration is not a file: ${selected.path}`);
    }

    const require = createRequire(pathToFileURL(cliEntrypoint));
    const parserPath = require.resolve("markdownlint-cli2/parsers/yaml");
    const { default: parseYaml } = await import(pathToFileURL(parserPath));

    const source = readFileSync(selected.path, "utf8");
    const parsed = parseYaml(source);
    const config = parsed ?? {};

    if (!isMapping(config)) {
        throw new Error("The project configuration must be a YAML mapping.");
    }

    const errors = [];

    for (const option of Object.keys(config)) {
        if (option !== "config") {
            errors.push(`Project configuration cannot define top-level "${option}". ` + 'Place Markdown rule overrides under "config:".');
        }
    }

    if ("config" in config && !isMapping(config.config)) {
        errors.push('"config:" must contain a YAML mapping of Markdown rules.');
    }

    report(
        {
            valid: errors.length === 0,
            configPath: selected.path,
            errors,
        },
        errors.length === 0 ? 0 : 1,
    );
}

main().catch((error) => {
    report(
        {
            valid: false,
            errors: [`Configuration validation failed: ${error.message}`],
        },
        2,
    );
});
