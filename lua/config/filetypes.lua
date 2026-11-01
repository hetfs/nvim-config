-- ============================================================
-- Custom filetype detection
-- ============================================================

vim.filetype.add({
  filename = {
    -- Docker Compose
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",

    -- GitLab CI
    [".gitlab-ci.yml"] = "yaml.gitlab",
    [".gitlab-ci.yaml"] = "yaml.gitlab",
  },

  pattern = {
    -- Ansible
    [".*/playbooks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/[^/]+/tasks/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/[^/]+/handlers/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/[^/]+/defaults/.*%.ya?ml"] = "yaml.ansible",
    [".*/roles/[^/]+/vars/.*%.ya?ml"] = "yaml.ansible",

    -- Helm
    [".*/charts/[^/]+/values[^/]*%.ya?ml"] = "yaml.helm-values",
  },
})
