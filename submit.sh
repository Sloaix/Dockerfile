#!/usr/bin/env bash

# 本脚本把本地改动提交并推送到 origin/master。
# 它不会创建 Git 标签或发布 Docker 镜像；正式版本仍由 GitHub Actions 生成。
set -euo pipefail

# 解析仓库路径并切换到项目根目录，确保从其他目录调用时行为一致。
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${repo_dir}"

# 提交说明必须作为唯一参数传入，并使用引号包住包含空格的内容：
#   ./submit.sh "chore: update ci image toolchain"
if (( $# != 1 )) || [[ -z "${1//[[:space:]]/}" ]]; then
    echo "Usage: ./submit.sh \"commit message\"" >&2
    exit 1
fi
commit_message="$1"

# 自动提交只允许在 master 分支执行，避免误把功能分支直接推到默认分支。
current_branch="$(git branch --show-current)"
if [[ "${current_branch}" != "master" ]]; then
    echo "Refusing to submit from branch '${current_branch:-detached HEAD}'." >&2
    echo "Switch to master before running this script." >&2
    exit 1
fi

# 确认 origin 存在，避免后面 fetch/push 使用一个不存在或拼错的远端。
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "Git remote 'origin' is not configured." >&2
    exit 1
fi

# 没有任何已跟踪、已暂存或未跟踪文件变化时，不创建空提交。
if [[ -z "$(git status --porcelain)" ]]; then
    echo "Nothing to commit."
    exit 0
fi

# 在创建本地提交前刷新 origin/master 状态。
# 如果远端包含本地没有的提交，则先停止，让用户同步代码后重新构建测试。
git fetch origin master
if ! git merge-base --is-ancestor origin/master HEAD; then
    echo "origin/master contains commits that are not in the local branch." >&2
    echo "Update master, rebuild, and run submit.sh again." >&2
    exit 1
fi

# 在暂存前检查已跟踪文件中的空白错误。
git diff --check

# 该仓库专用于单个镜像项目，因此统一暂存仓库内的新增、修改和删除。
# 提交前把文件列表和统计输出到终端，方便在日志中确认提交范围。
git add --all
git diff --cached --check

echo
echo "Changes to commit:"
git diff --cached --stat
echo

# 创建本地提交。若提交钩子拒绝提交，严格模式会停止脚本且不会执行 push。
git commit --message "${commit_message}"

# 推送到固定的 origin/master。
# 若网络错误或远端在 fetch 后发生变化，提交仍安全保留在本地，可在处理后重试 push。
if ! git push origin master; then
    echo "Push failed; the commit is still available in the local master branch." >&2
    exit 1
fi

echo
echo "Submitted to origin/master successfully."
echo "GitHub Actions will now build and validate the image."
