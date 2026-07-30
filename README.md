# Docker CI image

这是一个基于 Alpine Linux 的通用 CI 工具箱镜像，发布到
[`sloaix/ci`](https://hub.docker.com/r/sloaix/ci)。

镜像包含 Go、Node.js、Deno、Python、OpenJDK、PostgreSQL Client、
Docker CLI/Buildx、FFmpeg、Gradle、Maven、CMake、Ninja、Protobuf 编译器，
以及常用命令行工具。

## 版本与发布原则

- 本地构建固定使用 `sloaix/ci:local`，不需要输入正式版本。
- 正式版本遵循语义化版本，例如 `v2.0.0`。
- 发布时只选择 `patch`、`minor` 或 `major`，版本号由 GitHub Actions
  根据最新 Git 标签自动计算。
- 镜像构建和冒烟测试通过后，工作流才会推送 Docker Hub。
- Docker 镜像发布成功后，工作流才会自动创建远端 Git 标签。
- 每次发布同时生成不可变版本标签和 `latest`，已经发布的版本不应覆盖。

这套顺序避免了手工输入版本、Docker 标签与 Git 标签不一致，以及错误标签
提前推送到远端等问题。

## 日常只需要两个脚本

更新 Dockerfile 时，本地流程只有两条命令：

```sh
# 1. 构建镜像并自动执行冒烟测试
./build.sh

# 2. 检查改动、创建提交并推送到 origin/master
./submit.sh "chore: update ci image toolchain"
```

`ci/test.sh` 仍然保留，因为本地构建和 GitHub Actions 共用同一套测试逻辑，
但日常不需要手工调用它。

## 构建并测试

前提条件：

- Docker Engine 或 Docker Desktop 已启动。
- 当前用户可以执行 `docker` 命令。

更新 [ci/Dockerfile](ci/Dockerfile) 后直接执行：

```sh
./build.sh
```

脚本会构建并测试：

```text
sloaix/ci:local
```

脚本默认使用 `--pull --no-cache`，确保基础镜像和 Alpine 软件包得到刷新。
开发期间需要加速重复构建时，可以复用缓存：

```sh
USE_CACHE=1 ./build.sh
```

通常不需要修改本地标签。如果确实需要并行保留实验镜像，可以通过环境变量覆盖：

```sh
IMAGE_NAME=my-account/ci IMAGE_TAG=experiment ./build.sh
```

`build.sh` 不接受版本位置参数，`./build.sh v2.0.0` 会直接失败，以免本地标签
被误认为正式发布版本。

需要排查问题时，仍可单独检查其他镜像：

```sh
./ci/test.sh sloaix/ci:latest
```

冒烟测试会确认主要命令存在、Python 模块可以导入、镜像源与时区配置有效，
并输出 Go、Node.js、Deno、Python、Java、PostgreSQL、Docker 等组件的
实际版本。

## 更新并发布 Dockerfile

整个流程不需要手工计算版本，也不需要执行 `git tag`。

### 1. 修改并验证

```sh
./build.sh
```

### 2. 提交到 master

```sh
./submit.sh "chore: update ci image toolchain"
```

`submit.sh` 会检查当前分支、远端状态、改动内容和空白错误，然后执行
`git add --all`、`git commit` 和 `git push origin master`。如果远端已经领先，
脚本会在提交前停止，要求同步代码并重新构建；如果推送阶段发生网络错误，本地提交
会被保留。

推送或创建 Pull Request 时，`Validate CI image` 工作流会构建镜像并执行
冒烟测试，但不会登录或发布到 Docker Hub。

### 3. 在 GitHub Actions 中发布

确认 `master` 验证通过后：

1. 打开 GitHub 仓库的 **Actions** 页面；
2. 选择 **Release CI image**；
3. 点击 **Run workflow**；
4. Branch 选择 `master`；
5. 只选择升级级别：`patch`、`minor` 或 `major`；
6. 再次点击 **Run workflow**。

升级级别含义：

| 选择 | 当前版本示例 | 自动生成 | 适用情况 |
| --- | --- | --- | --- |
| `patch` | `v1.2.9` | `v1.2.10` | 安全更新、补丁升级、低风险修复 |
| `minor` | `v1.2.9` | `v1.3.0` | 增加工具或可能影响使用方式的升级 |
| `major` | `v1.2.9` | `v2.0.0` | 删除工具、默认行为变化、不兼容升级 |

本次从 Alpine 3.20 升级到 3.24，并包含 Deno 1 → 2、PostgreSQL 16 → 18
等不兼容变化，应该选择 `major`，工作流会从当前 `v1.2.9` 自动生成
`v2.0.0`。

如果安装了 GitHub CLI，也可以从命令行启动，无需输入具体版本号：

```sh
gh workflow run release.yml --ref master -f bump=major
```

### 4. 工作流自动执行的操作

`Release CI image` 会严格按照以下顺序运行：

1. 确认任务从 `master` 分支启动；
2. 读取最新远端语义化版本标签；
3. 根据选择自动计算下一版本；
4. 无缓存构建候选镜像；
5. 执行完整冒烟测试；
6. 推送 `sloaix/ci:vX.Y.Z` 和 `sloaix/ci:latest`；
7. 生成 SBOM 和构建来源证明；
8. 最后自动创建并推送同名 Git 标签。

同一时间只允许一个发布任务运行，因此两个发布不会计算出相同版本。

## 失败时如何处理

- 在镜像推送前失败：不会产生 Docker 版本，也不会产生 Git 标签。修复代码后
  重新运行发布即可。
- 镜像推送成功、最后创建 Git 标签失败：最新 Git 标签没有变化，重新运行相同的
  升级级别即可恢复；工作流会重新得到同一个版本号。
- 工作流已经成功：不要手工删除或覆盖版本标签。新改动应再次选择合适的升级级别。

不再需要执行以下容易出错的命令：

```sh
git tag -a v2.0.0 -m "Release v2.0.0"
git push origin v2.0.0
```

## 首次配置 GitHub Actions

仓库的 **Settings → Secrets and variables → Actions** 中必须存在：

- `DOCKER_USERNAME`：Docker Hub 用户名。
- `DOCKER_ACCESS_TOKEN`：Docker Hub Access Token，不要使用账户密码。

GitHub Actions 还必须允许工作流使用 `GITHUB_TOKEN` 写入仓库内容，以便自动
创建标签。若仓库覆盖了工作流中的权限，请在
**Settings → Actions → General → Workflow permissions** 中允许写权限。

普通分支验证不读取 Docker Hub 凭据，只有手动发布任务才会使用它们。

## 发布后检查

在 Actions 任务摘要中可以看到自动生成的版本和镜像摘要。发布成功后可检查：

```sh
docker pull sloaix/ci:v2.0.0
./ci/test.sh sloaix/ci:v2.0.0
```

也可以确认远端标签：

```sh
git fetch --tags
git tag --sort=-version:refname | sed -n '1,5p'
```

## 自定义镜像源和时区

Dockerfile 提供以下构建参数：

| 参数 | 默认值 |
| --- | --- |
| `TIMEZONE` | `Asia/Shanghai` |
| `GO_PROXY` | `https://goproxy.cn,direct` |
| `NPM_REGISTRY` | `https://registry.npmmirror.com` |
| `PIP_INDEX_URL` | `https://mirrors.cloud.tencent.com/pypi/simple` |

例如，构建使用官方公共源的镜像：

```sh
docker build --pull --no-cache \
  --build-arg GO_PROXY=https://proxy.golang.org,direct \
  --build-arg NPM_REGISTRY=https://registry.npmjs.org \
  --build-arg PIP_INDEX_URL=https://pypi.org/simple \
  --tag sloaix/ci:public \
  ./ci
```

## 构建工具选择

镜像预装以下跨语言构建基础：

- `build-base`：GCC、G++、Make、libc 开发头文件和链接工具，支持 Go cgo、
  Java JNI 和 Node.js 原生扩展。
- `cmake`、`samurai`、`pkgconf`：供需要 C/C++ 依赖的现代构建流程使用；
  Samurai 提供兼容的 `ninja` 命令。
- `protoc`：生成 Go、Java、JavaScript/TypeScript 等语言的 Protobuf 代码。
- `gcompat`：提高部分面向 glibc 发布的 Node.js 原生工具在 Alpine/musl 上的兼容性。
- `jq`、`yq`：在 CI 脚本中处理 JSON 和 YAML。
- `zip`、`unzip`、GNU `tar`：构建产物归档和解包。
- `openssh-client`：通过 SSH 拉取 Git 私有依赖。
- `coreutils`、`findutils`：减少构建脚本与 BusyBox 工具行为差异导致的问题。

下面这些工具不全局安装，应由每个项目自己的版本文件和 lockfile 管理：

- TypeScript、Vite、Webpack、Rollup、ESBuild、SWC；
- ESLint、Prettier、Vitest、Jest；
- Go linter、代码生成插件和 `protoc-gen-*`；
- Java 项目的 Gradle Wrapper 或 Maven Wrapper 插件依赖。

例如，TypeScript 项目应在自己的 `package.json` 中声明版本，然后通过
`pnpm install --frozen-lockfile`、`npm ci` 或 `yarn install --immutable`
进行可复现安装。Deno 本身可以直接执行和检查 TypeScript，不需要额外安装
全局 TypeScript 编译器。

Java 暂时保留 OpenJDK 21：它是兼容性成熟的 LTS 版本，并且能稳定运行 Alpine
3.24 当前提供的 Gradle 8.14。运行 Gradle 8.14 时不应直接切换到 JDK 25；
如果以后升级到 Gradle 9.1 或更高版本，可以再统一评估 OpenJDK 25。

Bun 目前没有加入，因为 Alpine 3.24 稳定仓库没有对应包。为了一个可选的
JavaScript 运行时混入 edge 仓库或执行未经包管理器跟踪的安装脚本，会降低镜像
的可复现性；Node.js、Deno、npm、pnpm 和 Yarn 已覆盖当前主要构建方式。

## 自动维护

- Pull Request 和 `master` 推送都会触发构建及冒烟测试。
- 正式发布只能通过手动发布工作流启动。
- Dependabot 每周检查 Alpine 基础镜像和 GitHub Actions 更新。
- 普通验证使用 GitHub Actions 缓存；正式候选镜像强制无缓存构建。
- 发布镜像包含版本、源码提交、构建时间、SBOM 和来源证明。

升级 Alpine 大版本时，需要同时检查带版本号的软件包，例如
`postgresql18-client` 和 `openjdk21`，并在本地执行完整冒烟测试。

## 项目结构

```text
.
├── .github/
│   ├── dependabot.yml
│   └── workflows/
│       ├── build_ci.yml
│       └── release.yml
├── ci/
│   ├── Dockerfile
│   └── test.sh
├── build.sh
├── submit.sh
└── README.md
```
