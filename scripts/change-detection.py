#!/usr/bin/env python3
"""
Optimized Komodo change detection with parallel API calls
Replaces serial requests with ThreadPoolExecutor for faster execution
"""

import tomllib
import json
import requests
import os
import sys

try:
    from concurrent.futures import ThreadPoolExecutor, as_completed
except ImportError as e:
    print(f"❌ Error: Required module not available: {e}")
    sys.exit(2)


API_URL = os.environ.get('KOMODO_API_URL')
API_KEY = os.environ.get('KOMODO_API_KEY')
API_SECRET = os.environ.get('KOMODO_API_SECRET')
MATCH_TAG = os.environ.get('ENVIRONMENT')

headers = {
    "Content-Type": "application/json",
    "X-API-KEY": API_KEY,
    "X-API-SECRET": API_SECRET
}

# ============================================================================
# API Functions with Error Handling
# ============================================================================

def api_read(request_type, params=None):
    """Query Komodo read API with error handling"""
    try:
        resp = requests.post(
            f"{API_URL}/read",
            headers=headers,
            json={"type": request_type, "params": params or {}},
            timeout=10
        )
        data = resp.json()
        if "error" in data:
            # Some endpoints may return partial data with an error
            if isinstance(data, dict) and len(data.keys()) > 1:
                print(f"⚠️ API Warning ({request_type}): {data['error']}")
                return [data]
            print(f"❌ API Error ({request_type}): {data['error']}")
            return []
        return data if isinstance(data, list) else [data] if data else []
    except requests.exceptions.Timeout:
        print(f"⏱️ API Timeout ({request_type}): Request took too long")
        return []
    except requests.exceptions.RequestException as e:
        print(f"❌ API Exception ({request_type}): {e}")
        return []
    except Exception as e:
        print(f"❌ Unexpected error ({request_type}): {e}")
        return []

def extract_id(value):
    """Extract MongoDB ObjectId from value"""
    if isinstance(value, dict) and "$oid" in value:
        return value.get("$oid")
    return value

# ============================================================================
# Parallel Resource Fetching
# ============================================================================

def fetch_resource_details(args):
    """Fetch details for a single resource - designed for parallel execution

    Args:
        args: tuple of (resource_type, resource_name, get_map, param_key, list_item)

    Returns:
        tuple: (resource_name, detail_dict or error_info)
    """
    resource_type, name, get_map, param_key, list_item = args
    try:
        detail = api_read(get_map[resource_type], {param_key[resource_type]: name})

        if isinstance(detail, list) and detail:
            detail = detail[0] if detail else None

        if not isinstance(detail, dict) or not detail.get("name"):
            # Try fetching by id if available
            raw_id = list_item.get("id") or list_item.get("_id")
            obj_id = extract_id(raw_id)
            if obj_id:
                detail = api_read(get_map[resource_type], {"id": obj_id})
                if isinstance(detail, list) and detail:
                    detail = detail[0] if detail else None

        if isinstance(detail, dict) and detail.get("name"):
            return name, detail, None
        else:
            # Fallback to list data if detail fetch fails
            return name, list_item or {"name": name}, f"Could not fetch full details"
    except Exception as e:
        return name, {"name": name}, str(e)

def get_komodo_resources_parallel(resource_type, desired_names=None):
    """Get detailed resources using parallel API calls (optimized version)

    Args:
        resource_type: One of 'stack', 'repo', 'server'
        desired_names: Optional list of names for special handling

    Returns:
        dict: {resource_name: detail_dict}
    """
    list_map = {
        "stack": "ListStacks",
        "repo": "ListRepos",
        "server": "ListServers"
    }
    get_map = {
        "stack": "GetStack",
        "repo": "GetRepo",
        "server": "GetServer"
    }
    param_key = {
        "stack": "stack",
        "repo": "repo",
        "server": "server"
    }

    # Get tag ID for environment filtering
    def get_tags(query=None):
        params = {"query": query} if query else {}
        tags = api_read("ListTags", params)
        return tags if isinstance(tags, list) else []

    def get_tag_id_by_name(name):
        tags = get_tags({"name": name})
        for tag in tags:
            if tag.get("name") == name:
                return extract_id(tag.get("id") or tag.get("_id"))
        return None

    tag_id = get_tag_id_by_name(MATCH_TAG)
    query_tags = [tag_id] if tag_id else [MATCH_TAG]

    # List resources with environment tag
    resources = api_read(list_map[resource_type], {"query": {"tags": query_tags}})

    # Special handling for servers without tags but matching names
    if resource_type == "server" and desired_names:
        all_servers = api_read("ListServers", {})
        tagged_names = {r.get("name") for r in resources if r.get("name")}
        for srv in all_servers:
            name = srv.get("name")
            if name and name in desired_names and name not in tagged_names:
                resources.append(srv)

    resources_by_name = {r.get("name"): r for r in resources if r.get("name")}
    names = sorted(resources_by_name.keys())

    if not names:
        return {}

    # Parallel fetch of resource details using ThreadPoolExecutor
    detailed = {}
    fetch_args = [
        (resource_type, name, get_map, param_key, resources_by_name.get(name, {}))
        for name in names
    ]

    print(f"  🔍 Fetching details for {len(names)} {resource_type}s in parallel...")

    with ThreadPoolExecutor(max_workers=5) as executor:
        # Submit all fetch tasks
        future_to_name = {
            executor.submit(fetch_resource_details, args): args[1]
            for args in fetch_args
        }

        # Collect results as they complete, with error handling
        completed = 0
        for future in as_completed(future_to_name):
            name = future_to_name[future]
            try:
                result_name, detail, error = future.result()
                detailed[result_name] = detail
                if error:
                    print(f"    ⚠️ {result_name}: {error}")
            except Exception as e:
                print(f"    ❌ {name}: Failed to fetch - {e}")
                detailed[name] = resources_by_name.get(name, {"name": name})
            completed += 1
            if completed % 5 == 0 or completed == len(names):
                print(f"    Progress: {completed}/{len(names)} completed")

    return detailed

# ============================================================================
# Helper Functions
# ============================================================================

def get_all_servers():
    """Get all servers to build ID-to-name mapping"""
    resources = api_read("ListServers", {})
    return {r.get("id"): r.get("name") for r in resources if r.get("id") and r.get("name")}

def get_all_repos():
    """Get all repos to build ID-to-name mapping"""
    resources = api_read("ListRepos", {})
    return {r.get("id"): r.get("name") for r in resources if r.get("id") and r.get("name")}

def get_all_tags():
    """Get all tags to build ID-to-name mapping"""
    def get_tags(query=None):
        params = {"query": query} if query else {}
        tags = api_read("ListTags", params)
        return tags if isinstance(tags, list) else []

    resources = get_tags()
    mapping = {}
    for tag in resources:
        tag_id = extract_id(tag.get("id") or tag.get("_id"))
        name = tag.get("name")
        if tag_id and name:
            mapping[tag_id] = name
    return mapping

def get_desired_resources(resource_type, file_path):
    """Get desired resources from TOML file"""
    try:
        with open(file_path, 'rb') as f:
            data = tomllib.load(f)
        resources = data.get(resource_type, [])
        return {
            r.get("name"): r
            for r in resources
            if r.get("name") and MATCH_TAG in r.get("tags", [])
        }
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return {}

def normalize_value(val):
    """Normalize values for comparison (handle None, empty strings, etc.)"""
    if val is None:
        return None
    if isinstance(val, str):
        cleaned = val.strip()
        return cleaned if cleaned != "" else None
    if isinstance(val, bool):
        return val
    if isinstance(val, (int, float)):
        return val
    if isinstance(val, list):
        normalized = []
        for item in val:
            n = normalize_value(item)
            if n is not None:
                normalized.append(n)
        return tuple(sorted(
            normalized,
            key=lambda x: json.dumps(x, sort_keys=True) if isinstance(x, (dict, list)) else str(x)
        ))
    if isinstance(val, dict):
        normalized = {}
        for k, v in val.items():
            n = normalize_value(v)
            if n is not None:
                normalized[k] = n
        return normalized
    return str(val).strip()

def get_current_value(desired_key, current_info, REPO_ID_TO_NAME):
    """Resolve current value for a desired config key, handling known aliases"""
    alias_map = {
        "linked_repo": ["linked_repo", "repo"],
        "repo": ["repo", "linked_repo"],
    }
    for key in alias_map.get(desired_key, [desired_key]):
        if key in current_info:
            value = current_info.get(key)
            if key == "linked_repo" and isinstance(value, str) and value in REPO_ID_TO_NAME:
                return REPO_ID_TO_NAME.get(value)
            return value
    return None

def has_current_key(desired_key, current_info):
    """Check if key exists in current info (with alias support)"""
    alias_map = {
        "linked_repo": ["linked_repo", "repo"],
        "repo": ["repo", "linked_repo"],
    }
    return any(key in current_info for key in alias_map.get(desired_key, [desired_key]))

def is_object_id(value):
    """Check if value looks like a MongoDB ObjectId"""
    if not isinstance(value, str):
        return False
    v = value.strip()
    return len(v) == 24 and all(c in "0123456789abcdef" for c in v.lower())

def compare_config(desired, current, resource_type, SERVER_ID_TO_NAME, TAG_ID_TO_NAME):
    """Compare configs to detect meaningful modifications"""
    desired_config = desired.get("config", {})
    current_info = {
        **(current.get("info") or {}),
        **(current.get("config") or {})
    }

    name = desired.get('name', 'unknown')
    differences = []

    # If we couldn't fetch details, skip diff to avoid false positives
    if not current_info:
        print(f"  ⏭️  SKIP: {name} - details unavailable from API")
        return False

    # Compare tags (top-level)
    desired_tags = normalize_value(desired.get("tags", []))
    current_tags_raw = current.get("tags") or current_info.get("tags") or []
    if current_tags_raw and all(is_object_id(str(t)) for t in current_tags_raw):
        mapped = [TAG_ID_TO_NAME.get(t) for t in current_tags_raw if TAG_ID_TO_NAME.get(t)]
        current_tags_norm = normalize_value(mapped) if mapped else None
    else:
        current_tags_norm = normalize_value([t for t in current_tags_raw if not is_object_id(str(t))])
    if desired_tags is not None and current_tags_norm is not None and desired_tags != current_tags_norm:
        differences.append(f"tags: '{desired_tags}' vs '{current_tags_norm}'")

    # Compare server assignment (stacks and repos have server references)
    if resource_type in ["stack", "repo"]:
        desired_server = desired_config.get("server")
        current_server_id = current_info.get("server_id") or current_info.get("server")
        current_server_id = extract_id(current_server_id)
        current_server = SERVER_ID_TO_NAME.get(current_server_id) if current_server_id else None

        if desired_server and desired_server != current_server:
            differences.append(f"server: '{desired_server}' vs '{current_server}'")

    # Compare config fields present in desired config (order-insensitive)
    ignored_keys = {"server"}
    for key, desired_val in desired_config.items():
        if key in ignored_keys:
            continue

        if not has_current_key(key, current_info):
            continue

        desired_norm = normalize_value(desired_val)
        if desired_norm is None:
            continue

        current_val = get_current_value(key, current_info, REPO_ID_TO_NAME)
        if current_val is None:
            continue
        current_norm = normalize_value(current_val)

        if desired_norm != current_norm:
            differences.append(f"{key}: '{desired_norm}' vs '{current_norm}'")

    if differences:
        print(f"  ✏️  MODIFIED: {name} - {differences}")
    else:
        print(f"  ✓  UNCHANGED: {name}")

    return len(differences) > 0

def detect_changes(resource_type, file_path, SERVER_ID_TO_NAME, REPO_ID_TO_NAME, TAG_ID_TO_NAME):
    """Detect added, removed, and modified resources (optimized with parallel API calls)"""
    desired = get_desired_resources(resource_type, file_path)
    desired_names = set(desired.keys())
    current = get_komodo_resources_parallel(resource_type, desired_names if resource_type == "server" else None)

    current_names = set(current.keys())

    added = desired_names - current_names
    removed = current_names - desired_names

    # Check for modifications in existing resources
    modified = set()
    for name in desired_names & current_names:
        if compare_config(desired[name], current[name], resource_type, SERVER_ID_TO_NAME, TAG_ID_TO_NAME):
            modified.add(name)

    return {
        "added": sorted(added),
        "removed": sorted(removed),
        "modified": sorted(modified),
        "current": sorted(current_names),
        "desired": sorted(desired_names)
    }

# ============================================================================
# Main Execution
# ============================================================================

def main():
    """Main change detection logic"""
    # Build ID-to-name mappings
    print("🔗 Building ID mappings...")
    SERVER_ID_TO_NAME = get_all_servers()
    REPO_ID_TO_NAME = get_all_repos()
    TAG_ID_TO_NAME = get_all_tags()
    print(f"✓ Loaded {len(SERVER_ID_TO_NAME)} servers for ID mapping")

    # Detect changes for each resource type
    print("=" * 60)
    print("📊 CHANGE DETECTION REPORT (Optimized with Parallel API Calls)")
    print("=" * 60)

    results = {}

    # Stacks
    print("\n📦 STACKS:")
    stacks = detect_changes("stack", "stacks/stacks.toml", SERVER_ID_TO_NAME, REPO_ID_TO_NAME, TAG_ID_TO_NAME)
    results["stacks"] = stacks
    print(f"  ➕ Added:    {stacks['added'] or 'None'}")
    print(f"  ➖ Removed:  {stacks['removed'] or 'None'}")
    print(f"  ✏️  Modified: {stacks['modified'] or 'None'}")

    # Repos
    print("\n📁 REPOS:")
    repos = detect_changes("repo", "repos/repos.toml", SERVER_ID_TO_NAME, REPO_ID_TO_NAME, TAG_ID_TO_NAME)
    results["repos"] = repos
    print(f"  ➕ Added:    {repos['added'] or 'None'}")
    print(f"  ➖ Removed:  {repos['removed'] or 'None'}")
    print(f"  ✏️  Modified: {repos['modified'] or 'None'}")

    # Servers
    print("\n🖥️  SERVERS:")
    servers = detect_changes("server", "servers/servers.toml", SERVER_ID_TO_NAME, REPO_ID_TO_NAME, TAG_ID_TO_NAME)
    results["servers"] = servers
    print(f"  ➕ Added:    {servers['added'] or 'None'}")
    print(f"  ➖ Removed:  {servers['removed'] or 'None'}")
    print(f"  ✏️  Modified: {servers['modified'] or 'None'}")

    # Check if any changes detected
    changes_detected = any(
        results[rt][change_type]
        for rt in ["stacks", "repos", "servers"]
        for change_type in ["added", "removed", "modified"]
    )

    print("\n" + "=" * 60)
    print(f"🔍 Changes Detected: {'YES' if changes_detected else 'NO'}")
    print("=" * 60)

    # Warnings for removals
    if results["stacks"]["removed"]:
        print(f"\n⚠️  Stacks will be REMOVED: {', '.join(results['stacks']['removed'])}")
    if results["repos"]["removed"]:
        print(f"\n⚠️  Repos will be REMOVED: {', '.join(results['repos']['removed'])}")
    if results["servers"]["removed"]:
        print(f"\n⚠️  Servers will be REMOVED: {', '.join(results['servers']['removed'])}")

    # Write outputs to GITHUB_OUTPUT
    def write_output(name, items):
        value = "\\n".join(items) if items else ""
        output_path = os.environ.get("GITHUB_OUTPUT")
        if output_path:
            with open(output_path, "a") as f:
                f.write(f"{name}={value}\n")
        else:
            print(f"  OUTPUT: {name}={value}")

    write_output("changes_detected", [str(changes_detected).lower()])
    write_output("stacks_added", results["stacks"]["added"])
    write_output("stacks_removed", results["stacks"]["removed"])
    write_output("stacks_modified", results["stacks"]["modified"])
    write_output("stacks_current", results["stacks"]["current"])
    write_output("stacks_desired", results["stacks"]["desired"])
    write_output("repos_added", results["repos"]["added"])
    write_output("repos_removed", results["repos"]["removed"])
    write_output("repos_modified", results["repos"]["modified"])
    write_output("repos_current", results["repos"]["current"])
    write_output("repos_desired", results["repos"]["desired"])
    write_output("servers_added", results["servers"]["added"])
    write_output("servers_removed", results["servers"]["removed"])
    write_output("servers_modified", results["servers"]["modified"])
    write_output("servers_current", results["servers"]["current"])
    write_output("servers_desired", results["servers"]["desired"])

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Fatal error in change detection: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(2)

