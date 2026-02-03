# Shared GitHub Actions for Komodo Deployments

This guide explains how to use the reusable GitHub Actions workflow for Komodo infrastructure deployments across all `infra-deploy-*` repositories.

## Overview

The reusable workflow (`.github/workflows/deploy-reusable.yml`) is maintained in the `noovoleum/infra-deploy-scripts` repository and provides:
- **Single source of truth** for deployment logic
- **Standardized deployments** across all environments
- **Eliminates duplication** - only 3 environment variables differ per repo

## Quick Start

### 1. Add the Submodule (if not already added)

```bash
cd your-infra-deploy-repo
git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
git commit -m "Add infra-deploy-scripts submodule"
```

### 2. Create Your Workflow

Create `.github/workflows/deploy.yml` in your repository:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      force_deploy:
        description: 'Force deploy all stacks (ignore change detection)'
        required: false
        default: false
        type: boolean
      redeploy_stacks:
        description: 'Specific stacks to redeploy (comma-separated)'
        required: false
        default: ''
        type: string
      dry_run:
        description: 'Dry run mode (validate only, no deployment)'
        required: false
        default: false
        type: boolean

jobs:
  deploy:
    uses: noovoleum/infra-deploy-scripts/.github/workflows/deploy-reusable.yml@main
    with:
      environment: singapore-prod        # Replace with your environment
      resource_sync_name: infra-deploy-singapore-prod  # Replace with your sync name
      repo_name: infra-deploy-singapore-prod           # Replace with your repo name
      force_deploy: ${{ inputs.force_deploy }}
      redeploy_stacks: ${{ inputs.redeploy_stacks }}
      dry_run: ${{ inputs.dry_run }}
    secrets: inherit
```

### 3. Configure Required Secrets

In your repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

| Secret | Description | Example |
|--------|-------------|---------|
| `KOMODO_API_URL` | Komodo API endpoint | `https://komodo.example.com/api` |
| `KOMODO_API_KEY` | Komodo API key | `your-api-key` |
| `KOMODO_API_SECRET` | Komodo API secret | `your-api-secret` |

## Configuration Parameters

The reusable workflow accepts the following parameters:

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `environment` | Environment name (used for tagging and filtering) | `singapore-prod`, `singapore-qa`, `devtools-prod` |
| `resource_sync_name` | Name of the ResourceSync in Komodo | `infra-deploy-singapore-prod` |
| `repo_name` | Repository name | `infra-deploy-singapore-prod` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `force_deploy` | Deploy all stacks regardless of changes | `false` |
| `redeploy_stacks` | Specific stacks to redeploy (comma-separated) | `''` |
| `dry_run` | Validate only, no deployment | `false` |

### Secrets

The workflow inherits these secrets from the caller:
- `KOMODO_API_URL`
- `KOMODO_API_KEY`
- `KOMODO_API_SECRET`

## Environment Variables Set by Workflow

The reusable workflow sets these environment variables automatically:

```yaml
env:
  ENVIRONMENT: ${{ inputs.environment }}
  RESOURCE_SYNC_NAME: ${{ inputs.resource_sync_name }}
  REPO_NAME: ${{ inputs.repo_name }}
```

**IMPORTANT**: The workflow now correctly uses `ENVIRONMENT` environment variable for tag filtering instead of hardcoded values. This is a critical bug fix from previous versions.

## Workflow Features

The reusable workflow includes:

### Validation Job
- ✅ Secret scanning (detects unencrypted `.env` files)
- ✅ TOML syntax validation
- ✅ Docker Compose file validation
- ✅ Komodo resource schema validation
- ✅ Change detection against Komodo state

### Deploy Job
- 🔄 Resource synchronization
- 📥 Repository cloning and pulling
- 🚀 Stack deployment (with change detection)
- 📊 Deployment summary in GitHub Actions UI

### Advanced Features
- 🔍 **DEBUG_KOMODO_PAYLOADS**: Set repository variable `DEBUG_KOMODO_PAYLOADS=true` to enable detailed API logging
- 🏷️ **Tag ID Mapping**: Automatically maps tag IDs to names for accurate filtering
- 🎯 **Object ID Handling**: Properly handles MongoDB ObjectId references
- 📋 **Full Outputs**: Complete change detection outputs for downstream jobs

## Example Configurations

### singapore-prod

```yaml
jobs:
  deploy:
    uses: noovoleum/infra-deploy-scripts/.github/workflows/deploy-reusable.yml@main
    with:
      environment: singapore-prod
      resource_sync_name: infra-deploy-singapore-prod
      repo_name: infra-deploy-singapore-prod
    secrets: inherit
```

### singapore-qa

```yaml
jobs:
  deploy:
    uses: noovoleum/infra-deploy-scripts/.github/workflows/deploy-reusable.yml@main
    with:
      environment: singapore-qa
      resource_sync_name: infra-deploy-singapore-qa
      repo_name: infra-deploy-singapore-qa
    secrets: inherit
```

### devtools-prod

```yaml
jobs:
  deploy:
    uses: noovoleum/infra-deploy-scripts/.github/workflows/deploy-reusable.yml@main
    with:
      environment: devtools-prod
      resource_sync_name: infra-deploy-devtools-prod
      repo_name: infra-deploy-devtools-prod
    secrets: inherit
```

## Updating the Reusable Workflow

When the reusable workflow is updated in `infra-deploy-scripts`:

```bash
# In your infra-deploy-* repo
git submodule update --remote lib/infra-deploy-scripts
git add lib/infra-deploy-scripts
git commit -m "chore: update infra-deploy-scripts to latest"
git push
```

Or use the just command:
```bash
just submodule-update
```

## Troubleshooting

### "No .env.encrypted files found"

Ensure you've encrypted your environment files:
```bash
just encrypt-all
```

### "MATCH_TAG is not defined"

This error should not occur with the new reusable workflow. If you see it, verify you're using the latest version of `infra-deploy-scripts`.

### "Failed to sync resources"

Check that:
1. Komodo API credentials are correct
2. `resource_sync_name` matches your Komodo configuration
3. Komodo server is accessible from GitHub Actions runners

### Debug Mode

Enable detailed API logging by setting a repository variable:
1. Go to **Settings** → **Secrets and variables** → **Variables**
2. Create a new variable named `DEBUG_KOMODO_PAYLOADS`
3. Set value to `true`

## Migration Guide

### From Standalone Workflow

If you have an existing standalone workflow:

1. **Add the submodule** (if not already added):
   ```bash
   git submodule add https://github.com/noovoleum/infra-deploy-scripts.git lib/infra-deploy-scripts
   ```

2. **Backup your current workflow**:
   ```bash
   cp .github/workflows/deploy.yml .github/workflows/deploy.yml.backup
   ```

3. **Replace with reusable workflow call** (see Quick Start above)

4. **Update required parameters**:
   - Replace hardcoded environment with `inputs.environment`
   - Update `resource_sync_name` and `repo_name`

5. **Test with dry run**:
   ```bash
   # In GitHub Actions, run workflow manually with dry_run=true
   ```

6. **Remove backup after testing**:
   ```bash
   rm .github/workflows/deploy.yml.backup
   ```

## Critical Bug Fix: MATCH_TAG Hardcoding

**Previous Behavior** (BUG):
```python
MATCH_TAG = "singapore-prod"  # HARDCODED - Does not use ENVIRONMENT variable!
```

**New Behavior** (FIXED):
```python
MATCH_TAG = os.environ.get('ENVIRONMENT')  # Uses environment variable correctly
```

This fix ensures that:
- ✅ Tag filtering uses the correct environment
- ✅ Workflow can be shared across repos without modification
- ✅ Environment-specific resources are properly filtered

## Workflow Outputs

The reusable workflow provides outputs for downstream jobs:

- `changes_detected`: Whether changes were detected
- `stacks_added`: Stack names that were added
- `stacks_removed`: Stack names that were removed
- `stacks_modified`: Stack names that were modified

Example usage:
```yaml
jobs:
  deploy:
    uses: noovoleum/infra-deploy-scripts/.github/workflows/deploy-reusable.yml@main
    # ... with and secrets ...

  notify:
    needs: deploy
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Send notification
        run: |
          echo "Changes detected: ${{ needs.deploy.outputs.changes_detected }}"
          echo "Stacks modified: ${{ needs.deploy.outputs.stacks_modified }}"
```

## Best Practices

1. **Always use `secrets: inherit`** to pass secrets from caller
2. **Keep workflow_dispatch inputs** in your wrapper for manual deployments
3. **Update submodules regularly** to get the latest fixes and features
4. **Test with dry_run first** when making changes
5. **Use environment-specific tags** in your stack definitions

## Related Documentation

- **[Encryption/Decryption Guide](encryption/README.md)** - Managing encrypted environment files
- **[Just Commands](README.md#just-commands)** - Using just for common operations
- **[Komodo Documentation](https://github.com/ISO-KOMODO/komodo)** - Komodo deployment platform

## Support

For issues or questions:
1. Check this documentation
2. Review the [troubleshooting section](#troubleshooting)
3. Check GitHub Actions workflow run logs
4. Verify `infra-deploy-scripts` submodule is up to date
