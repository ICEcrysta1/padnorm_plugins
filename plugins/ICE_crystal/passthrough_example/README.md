# 直通示例

这是随主仓库提供的普通 Lua 插件目录，不是 Git 子模块。它分别注册“直通按钮”“直通摇杆”和“直通扳机”，接收主程序送来的抽象输入，默认保持直通，没有额外动作、后台任务或依赖。

- `manifest.yaml`：声明固定 GUID、插件名称、展示版本与简介、logo、注册按钮及其图标；GUID 沿用在线仓库官方插件示例的 `019b6bae-8fc4-49c9-aef2-2e392d022e7e`。
- `icon.png`：由主程序现有 `plugin.svg` 导出的 PNG，供示例 logo 和直通按钮共同使用；可自行替换图片及声明路径。
- `main.lua`：插件入口；修改 `process_button`、`process_stick` 或 `process_trigger` 即可加入自己的处理逻辑。

将整个 `passthrough_example` 文件夹复制到 **EXE 同级的 `plugins/`** 下，再启动或重启程序，无须重新编译。例如本仓库的 Release 目录为 `target/release/plugins/passthrough_example/`。

调试时直接修改运行目录中的 `main.lua`，或将源码改动复制过去后重启；程序读取的是 EXE 同级的安装副本。

在按钮映射界面选择一个物理按钮，将目标类型切换为“插件”，选择“直通示例 / 直通按钮”并保存。这个逻辑按钮可以接收三角、Y 或其它按钮，Lua 源码只使用注册 ID，不依赖手柄品牌和物理按键名称。

配置中的目标为：

```yaml
target:
  plugin:
    plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e
    id: passthrough
```

每个注册 ID 对应一个独立直通按钮。需要多个独立按钮时，在声明的 `buttons` 表中增加不同 ID；脚本会自动遍历这些输入。将多个物理按钮绑定到同一 ID 会先聚合输入，并把结果贡献给这些绑定位置。

摇杆和扳机在对应属性页的“附加插件”中选择。配置示例：

```yaml
left_stick:
  plugin: {plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e, id: stick}
left_trigger:
  plugin: {plugin: 019b6bae-8fc4-49c9-aef2-2e392d022e7e, id: trigger}
```

三个处理函数都先把逻辑输入复制成期望状态，源码中的这些函数就是修改入口：

- 按钮和扳机分别保留 `pressed` 与 `value`，不从行程推导按下状态；宿主按 OR / 最大行程合并贡献。
- 摇杆的期望位置减去输入位置后作为增量返回，默认增量为零，避免主体与插件各输出一份原始坐标而翻倍，也不提前量化。

默认单源绑定、保留原有手柄输出映射时保持直通。需要独立处理左右轴时，为各轴增加不同注册 ID。完整输入输出、生命周期及异步接口见[插件说明](../README.md)。
