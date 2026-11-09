# DevOps Lab

## Jenkins 基础 CI 练习（视频第 10P，课程第 9 节）

课程：[B 站第 10 集](https://www.bilibili.com/video/BV1pP411z7p8/?p=10)。

流程：Git 拉取 → Spring Boot / Maven 构建 → SSH 传输 JAR → Docker Compose 部署 → HTTP 验证。

## 与视频的对应和差异

- 沿用项目名和自由风格作业名 **mytest**、**TestController**、**target/mytest.jar**，以及 `/test` 返回 **Hello Jenkins!**。
- 视频使用 Spring Boot 2.6.1 / Java 8；这里使用 Maven Central 已发布的稳定版 **Spring Boot 4.1.2**，配合环境现有的 **JDK 21**。Docker 运行时选择支持 ARM64 的官方 Temurin JRE 21。
- 视频 Maven Goals 为 `clean package -DskipTests`；这里执行 `clean verify`，保留 3 个 HTTP 集成测试，再运行可执行 JAR 检查。
- 没有配置 webhook，使用 **Build Now** 手动构建。
- Jenkins 只拉取、测试、打包和归档。**不挂载 Docker socket，不配置有 Docker 权限的 SSH 账户，不存入私钥或部署凭据**。Docker 部署由用户在 Ubuntu 终端单独执行。
- 视频使用 `/usr/local/test/docker` 和全接口 `8081:8080`；这里使用用户目录 `~/devops-lab/episode-10/deploy` 和 **127.0.0.1:8081:8080**。不改动现有 Jenkins 8080 或 Python 服务 8000。
- 不执行视频的 `docker-compose down`、`docker image prune -f`，也不删除镜像、卷或旧服务数据。

## 目录

- `src/`：Spring Boot 应用与测试。
- `pom.xml`：JDK 21 构建配置，产物固定为 `target/mytest.jar`。
- `jenkins/freestyle-build.sh`：课程风格的 Jenkins 自由风格构建脚本。
- `Jenkinsfile`：可选 Pipeline 版本，与自由风格方式二选一。
- `scripts/verify-jar.sh`：直接启动 JAR 并检查 HTTP，退出时仅停止自身启动的 Java 进程。
- `deploy/`：Dockerfile、Compose 和严格的构建上下文白名单。
- `VERIFICATION.md`：实际验证结果和未完成项目。

## 在 Ubuntu 构建和测试

需要 JDK 21、Maven 3.9+、Bash、curl。在本目录运行：

```bash
mvn -B -ntp clean verify
bash scripts/verify-jar.sh
```

HTTP 测试覆盖 `/test` 的状态码、响应正文和类型，`/health`，以及不存在路径的 404。JAR 检查使用回环端口 18081；若占用，可指定另一个空闲端口：

```bash
VERIFY_PORT=18082 bash scripts/verify-jar.sh
```

不要使用现有服务占用的端口。`target/`、日志、部署用 JAR 和环境文件不会进入 Git。

## Jenkins：创建 mytest 自由风格作业

1. **New Item → mytest → Freestyle project**。如果已有同名作业，先检查，不覆盖。
2. Git SCM 仓库：`https://github.com/lzddyx/devops-lab.git`。分支：`*/main`。公开仓库可不填凭据；私有仓库需单独授权最小只读访问，不能把令牌或密钥写入脚本。
3. JDK 选择现有 `jdk21`，路径 `/opt/java/openjdk`。
4. 添加 **Invoke top-level Maven targets**：Maven `maven3`，Goals `clean verify`，在 Advanced 的 POM 中填 `pom.xml`。
5. 再加 **Execute shell**：

   ```bash
      bash scripts/verify-jar.sh
   ```

6. 构建后操作添加 **Publish JUnit test result report**：`target/surefire-reports/*.xml`。
7. 添加 **Archive the artifacts**：`target/mytest.jar`，启用 fingerprint。
8. 保存并点击 **Build Now**。检查测试报告、JAR 检查输出和归档 JAR。

另一种等效构建方式是用单个 Execute shell 步骤 `bash jenkins/freestyle-build.sh`，不再重复执行上面的 Maven 和 shell 两步。现有 Jenkins 镜像已经在 PATH 上提供 Maven。

可选 Pipeline 的 Script Path 为 `Jenkinsfile`。该文件同样不部署、不使用 SSH。

## 用 Mac 已有 SSH 通道传 JAR

先在 Mac 终端设置 `VM_USER`（Ubuntu 用户名）和 `VM_HOST`（虚拟机地址）。不要把密码填入这些变量。

从成功的 Jenkins 构建下载 `mytest.jar` 到 Mac 的临时目录，在 Mac 的仓库根目录执行。这里的 SSH 命令由用户运行，不放入 Jenkins 作业：

```bash
ssh "${VM_USER}@${VM_HOST}" 'mkdir -p ~/devops-lab/episode-10/deploy'
scp /path/to/mytest.jar "${VM_USER}@${VM_HOST}":devops-lab/episode-10/deploy/mytest.jar
scp deploy/Dockerfile deploy/compose.yaml deploy/.dockerignore "${VM_USER}@${VM_HOST}":devops-lab/episode-10/deploy/
```

Mac 上运行 `shasum -a 256 /path/to/mytest.jar`，Ubuntu 上运行 `sha256sum ~/devops-lab/episode-10/deploy/mytest.jar`，两边结果应相同。不要复制整个 Jenkins 数据目录、`.ssh`、凭据或完整工作区。

## 用户在 Ubuntu 单独部署 Docker

当前 Ubuntu 练习用户需要 sudo 才能操作 Docker。密码只在自己的终端输入，不发到聊天，也不放进代码。

先确认 8081 未被占用，且 `devops-episode10` 没有同名的其他项目：

```bash
ss -ltn 'sport = :8081'
sudo docker ps -a --filter label=com.docker.compose.project=devops-episode10
```

若有已有监听或容器，先核对归属；不是本练习的内容就停止，不覆盖。

```bash
cd ~/devops-lab/episode-10/deploy
sudo docker compose config --quiet
sudo docker compose build
sudo docker compose up -d --no-build --pull never
sudo docker compose ps
curl --fail http://127.0.0.1:8081/test
curl --fail http://127.0.0.1:8081/health
```

预期返回 `Hello Jenkins!` 和 `OK`。若 Docker Hub 连接被重置，保留错误并停止；不使用未经验证的镜像源，也不关闭 TLS 校验。Dockerfile 使用官方可变 tag，成功拉取后应记录实际 digest；当前不声称镜像位级可复现。

从 Mac 浏览器访问时，在自己的终端保持此转发打开：

```bash
ssh -N -L 127.0.0.1:8081:127.0.0.1:8081 "${VM_USER}@${VM_HOST}"
```

打开 http://127.0.0.1:8081/test。若要停止本示例，在它的部署目录运行 `sudo docker compose stop`，不影响其他 Compose 项目。

## 验证记录

以 [VERIFICATION.md](VERIFICATION.md) 为准。已有配置文件不代表 Jenkins 构建或 Docker 部署已经成功。
