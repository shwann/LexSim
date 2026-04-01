# Stage 1：Node.js 20（Vite 7 / @vitejs/plugin-vue 6 要求 >=20）
FROM node:20-slim AS node-base

# Stage 2：主镜像 Python 3.11 + Node.js 20
FROM python:3.11-slim

# 代理构建参数（Apple Silicon 通过 host.docker.internal 使用宿主机代理）
ARG http_proxy
ARG https_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=${http_proxy} \
    https_proxy=${https_proxy} \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

# 安装编译工具（--fix-missing 应对偶发 502，psutil 等 C 扩展包备用）
RUN apt-get update \
 && apt-get install -y --no-install-recommends --fix-missing gcc build-essential \
 && rm -rf /var/lib/apt/lists/*

# 从 node:20-slim 复制 Node.js 二进制和 npm 包
COPY --from=node-base /usr/local/bin/node   /usr/local/bin/node
COPY --from=node-base /usr/local/lib/node_modules /usr/local/lib/node_modules

# 用软链接创建 npm/npx（避免直接 COPY 破坏内部相对路径引用）
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
 && chmod +x /usr/local/bin/npm /usr/local/bin/npx

# 从 uv 官方镜像复制 uv
COPY --from=ghcr.io/astral-sh/uv:0.9.26 /uv /uvx /bin/

WORKDIR /app

# 先复制依赖描述文件以利用层缓存
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/package-lock.json ./frontend/
COPY backend/pyproject.toml backend/uv.lock ./backend/

# 安装依赖（Node + Python）
RUN npm ci \
 && npm ci --prefix frontend \
 && cd backend && uv sync

# 构建完成后清除代理（运行时不需要）
ENV http_proxy= \
    https_proxy= \
    HTTP_PROXY= \
    HTTPS_PROXY=

# 复制项目源码
COPY . .

EXPOSE 3000 5001

CMD ["npm", "run", "dev"]
