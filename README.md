# 说明
本项目是一个名为“种子”（Zhongzi）的操作系统创建器。

操作系统创建器可用于创建一个能够通过脚本生成目标系统或编译软件的工具。

## 获取方式：

“种子”系统创建器可以通过git命令进行获取，使用以下命令获取最新的版本：

```sh
git clone https://github.com/sunhaiyong1978/Zhongzi.git --depth 1
```

## 运行环境：
“种子”系统创建器通过 bash 运行脚本来工作，因此可在大多数通用Linux系统中运行。


## 基本使用方式：

当获取了“种子”系统创建器的代码和准备好运行环境后就可以创建一个自己的发行版。

使用以下的步骤使用现有的资源创建一个发行版：

```sh
pushd Zhongzi
	./init_distro.sh -a loongarch64 Yongbao default
	./make_distro.sh Yongbao loongarch64
popd
```

上述步骤中：
init_distro.sh 脚本用于创建发行版的目录结构以及复制构建发行版所需的相关脚本和文件，完成该命令后会在 distro 目录中生成指定名称的目录，该目录即新生成的发行版构建环境。
make_distro.sh 脚本用于将指定仓库中的各种“种子”文件创建成为构建软件包所使用的脚本和配置文件并存放在 distro 目录发行版名称的目录中。

通过上述步骤即创建了一个叫“Yongbao”的Linux发行版构建环境。

此时可使用发行版目录中的脚本进行发行版的构建过程。可参考如下步骤：

```sh
pushd Zhongzi/distro/Yongbao/loongarch64
	./build.sh
popd
```

使用 init_distro.sh 脚本创建发行版的时候还可以通过指定默认的步骤文件来设置目标系统。如：

```sh
pushd Zhongzi
	./init_distro.sh -a loongarch64 -S clfs TestOS clfs
	./make_distro.sh -N Current -f TestOS loongarch64
popd
```

make_distro.sh 脚本使用 -N 参数可以指定一个版本组合的名称，可用的名称在 package_version 目录中。

该命令会进行目标指令集架构操作系统的构建，在构建前会对构建过程中所需的源码包和资源文件进行下载，请保持网络环境的畅通。

可以通过 -h 参数获取build.sh命令的基本用法说明。

## 感谢
感谢你关注本项目的内容。
