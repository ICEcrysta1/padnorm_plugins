# 直通示例

这是官方 Lua 直通示例。它分别注册“直通按钮”“直通摇杆”和“直通扳机”，接收主程序送来的抽象输入，默认保持直通，没有额外动作、后台任务或依赖。

- `manifest.yaml`：声明固定 GUID、七种语言的名称与简介、默认语言 `en`、展示版本、logo、注册控件及其图标；GUID 沿用在线仓库官方插件示例的 `019b6bae-8fc4-49c9-aef2-2e392d022e7e`。
- `icon.png`：由主程序现有 `plugin.svg` 导出的 PNG，供示例 logo 和直通按钮共同使用；可自行替换图片及声明路径。
- `main.lua`：插件入口；修改 `process_button`、`process_stick` 或 `process_trigger` 即可加入自己的处理逻辑。
- `config.yaml`：由 manifest 的 `config` 指定，声明两个开关、百分比滑块和手柄按钮选择，名称与说明提供七种语言，默认语言沿用 manifest；控件顺序、文字、范围、步长及默认值由插件定义。

将整个 `passthrough_example` 文件夹复制到 **EXE 同级的 `plugins/offline/`** 下，再启动或重启程序，无须重新编译；也可以使用“从文件安装”选择本目录的 `manifest.yaml`。构建不会自动复制此示例。例如本仓库的 Release 目录为 `target/release/plugins/offline/passthrough_example/`。

调试时直接修改运行目录中的 `main.lua`，或将源码改动复制过去后重启；程序读取的是 EXE 同级的安装副本。

在按钮映射界面选择一个物理按钮，将目标类型切换为“插件”，选择“直通示例 / 直通按钮”并保存。这个逻辑按钮可以接收三角、Y 或其它按钮，Lua 源码只使用注册 ID，不依赖手柄品牌和物理按键名称。

配置中的目标为：

```yaml
target:
  plugin:
    plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e
    id: passthrough
```

每个注册 ID 对应一个独立直通按钮。需要多个独立按钮时，在声明的 `buttons` 表中增加不同 ID；脚本会自动遍历这些输入。将多个物理按钮绑定到同一 ID 时，先按下的绑定优先，松开后才交接。

摇杆和扳机在对应属性页的“附加插件”中选择。配置示例：

```yaml
axes:
  left_stick:
    kind: stick
    plugin: {plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e, id: stick}
  left_trigger:
    kind: trigger
    plugin: {plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e, id: trigger}
```

三个处理函数分别返回按钮贡献、摇杆增量和扳机行程增量。

- 按钮分别保留 `pressed` 与 `value`，宿主按 OR 和最大行程合并。
- 摇杆默认返回零增量。扳机按强度计算行程增量，100% 时为零。宿主将增量叠加到曲线前的轴输入，再应用当前映射的死区和曲线。

插件管理页的两个开关和启用按钮属于全局配置，Lua 在 `init` 中通过 `host.config` 读取。开启「按住按钮启用」后，普通按钮（如 `{button: south}`）从 `input.raw.buttons` 读取；实体扳机（如 `{axis: left_trigger}`）从 `input.raw.axes` 读取。v0.1.2 需要支持该轴接口的 PadNorm。

扳机输出强度在 `config.yaml` 中标为 `scope: binding`，默认 100%。把扳机的附加插件选为「直通示例 / 直通扳机」，在右栏「插件配置」里调整，再点「保存并应用」。Lua 在 `process` 中通过 `input.controls.triggers.trigger.config.trigger_strength` 读取当前绑定的值。扳机释放后，该绑定配置可能缺失。

需要独立处理左右轴时，为各轴增加不同注册 ID。完整配置格式、输入输出、生命周期及异步接口见[插件说明](https://github.com/ICEcrysta1/PadNorm/blob/main/docs/plugins/README.md)。

本项目采用 **The MIT License（MIT）**，完整条款见 [LICENSE](./LICENSE)。

Copyright (C) 2026 ICE_crystal.
