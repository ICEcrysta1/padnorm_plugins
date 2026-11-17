# GitHub 主题集

- GitHub Dark Default
- GitHub Dark High Contrast
- GitHub Dark Colorblind
- GitHub Dark Dimmed
- GitHub Light Default
- GitHub Light High Contrast
- GitHub Light Colorblind
- GitHub Light（经典）
- GitHub Dark（经典）

在 PadNorm 中从文件安装本目录的 `manifest.yaml`，然后在设置页“其他”的主题配色中选择并保存。需要支持 `themes` 能力和 Lua `theme(id, host)` 回调的宿主版本。

配色来源为 primer/github-vscode-theme 的 `cd78e5e4e7bcf132a6f428ae0f32264bb1b729cf` 提交及其固定依赖 `@primer/primitives` 7.10.0；经典主题使用同提交 `src/classic/colors.json`（基于 `@primer/primitives` 2.0.1）。Default 与 Light Default 同步使用上游 `src/colors.js` 对前景、次要文字和强调色的覆盖，Colorblind 沿用蓝色成功状态和橙色危险状态。

## 现代主题字段映射

| 宿主字段 | 上游字段 |
| --- | --- |
| `background` | `canvas.default` |
| `panel` | `canvas.inset` |
| `outline` | `border.default` |
| `drag_handle` | `border.default` |
| `text` | `fg.muted` |
| `text_tertiary` | `fg.subtle` |
| `control` | `btn.bg` |
| `control_hover` | `btn.hoverBg` |
| `control_outline` | `border.muted` |
| `mapping_line` | 优先沿用 `control_outline`；普通深色取 `scale.gray.5`，普通浅色取 `scale.gray.4`，高对比主题保持同色 |
| `text_primary` | `fg.default` |
| `mapping_icon_foreground` | `fg.default`，仅替换按钮提示 SVG 的中性色 |
| `controller_foreground` | 与 `text_bright` 相同的色阶值，独立控制主手柄底图 |
| `text_bright` | `scale.gray.0`，浅色取 `scale.gray.9` |
| `accent_background` | `accent.subtle`，叠加于 `canvas.default` |
| `accent_emphasis` | `accent.emphasis` |
| `navigation_background` | `accent.subtle`，叠加于 `canvas.inset` |
| `blue` | `accent.fg` |
| `blue_text` | `scale.blue.2`，浅色取 `scale.blue.7` |
| `curve` | `scale.blue.3`，浅色取 `scale.blue.6` |
| `axis` | `fg.subtle` |
| `success` | `btn.primary.bg` |
| `success_outline` | `success.fg` |
| `success_foreground` | `btn.primary.text` |
| `success_text` | `scale.green.1`，浅色取 `scale.green.8` |
| `warning` | `attention.fg` |
| `danger` | `danger.fg` |

上游颜色映射到宿主现有的 30 个 RGB 字段。透明背景合成后四舍五入到 8 位通道。浅色主题的灰、蓝、绿色阶使用反向索引，取值均来自对应的上游调色板。需要宿主支持 `success_foreground`、`mapping_icon_foreground`、`controller_foreground`、`controller_glow`、`controller_inner_glow`、`controller_flow` 和 `mapping_line` 字段；深色 High Contrast 的成功按钮使用原版深色文字。

## 经典主题字段映射

| 宿主字段 | `src/classic/theme.js` 字段 |
| --- | --- |
| `background` | `editor.background` |
| `panel` | `sideBar.background` |
| `outline` | `sideBar.border` |
| `drag_handle` | `sideBar.border` |
| `text` | `descriptionForeground` |
| `text_tertiary` | 调色板 `gray[4]` |
| `control` | `button.secondaryBackground` |
| `control_hover` | `button.secondaryHoverBackground` |
| `control_outline` | `checkbox.border` |
| `mapping_line` | 经典深色取原始 `gray[6]`（`#586069`），经典浅色取原始 `gray[4]`（`#959da5`），提高对背景的辨识度 |
| `text_primary` | `editor.foreground` |
| `mapping_icon_foreground` | `editor.foreground`，仅替换按钮提示 SVG 的中性色 |
| `controller_foreground` | 与 `text_bright` 相同的色阶值，独立控制主手柄底图 |
| `text_bright` | 原始调色板 `black`；深色取原始 `gray[0]`（反转后的 `gray[9]`） |
| `accent_background` | `list.hoverBackground` |
| `accent_emphasis` | `activityBarBadge.background` |
| `navigation_background` | `list.activeSelectionBackground` |
| `blue` | `textLink.foreground` |
| `blue_text` | `terminal.ansiBrightBlue` |
| `curve` | `editorGutter.modifiedBackground` |
| `axis` | 调色板 `gray[4]` |
| `success` | `button.background` |
| `success_outline` | `gitDecoration.addedResourceForeground` |
| `success_foreground` | `button.foreground` |
| `success_text` | 调色板 `green[6]`，深色为 `green[4]` |
| `warning` | `notificationsWarningIcon.foreground` |
| `danger` | `errorForeground` |

经典主题使用 10 级色阶，深色变体反转色阶数组并互换 `white` 与 `black`。上游经典深色主题中引用 `white` 的边框因此取原始 `black`（`#1b1f23`）；本插件的标题与主手柄底图取原始 `gray[0]`（`#fafbfc`，反转后的 `gray[9]`），正文和按钮提示图标使用上游 `editor.foreground`。

## 连接线与光晕

`mapping_line` 仅控制未选中的映射连接线，选中线仍使用 `blue`。连接线优先与控件描边同色；普通主题的原描边对背景对比不足，因此改取同主题上游灰阶，不改变控件边框。两套 High Contrast 主题沿用各自的 `control_outline`。调整后的普通主题连接线对 `background` 和 `panel` 的计算对比度均不低于约 2.2:1，用于保持可辨识且弱于选中线的视觉层级，并非文字可访问性标准。

`controller_glow` 和 `controller_inner_glow` 取 `accent_emphasis`，分别控制外发光与内发光；`controller_flow` 取上游函数名紫色：现代浅色 `purple[5]`、深色 `purple[2]`，经典主题使用 `entity` 配色。

来源与 MIT 许可证原文随插件分发。

- https://github.com/primer/github-vscode-theme/tree/cd78e5e4e7bcf132a6f428ae0f32264bb1b729cf
- https://www.npmjs.com/package/@primer/primitives/v/7.10.0
- `LICENSES.txt`
