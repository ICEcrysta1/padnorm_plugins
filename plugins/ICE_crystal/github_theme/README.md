# GitHub 深色主题集

- GitHub Dark Default
- GitHub Dark High Contrast
- GitHub Dark Colorblind
- GitHub Dark Dimmed

在 PadNorm 中从文件安装本目录的 `manifest.yaml`，然后在设置页“其他”的主题配色中选择并保存。需要支持 `themes` 能力和 Lua `theme(id, host)` 回调的宿主版本。

配色来源为 primer/github-vscode-theme 的 `cd78e5e4e7bcf132a6f428ae0f32264bb1b729cf` 提交及其固定依赖 `@primer/primitives` 7.10.0。Default 同步使用上游 `src/colors.js` 对前景、次要文字和强调色的覆盖，Colorblind 沿用蓝色成功状态和橙色危险状态。

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
| `text_primary` | `fg.default` |
| `text_bright` | `scale.gray.0` |
| `accent_background` | `accent.subtle`，叠加于 `canvas.default` |
| `accent_emphasis` | `accent.emphasis` |
| `navigation_background` | `accent.subtle`，叠加于 `canvas.inset` |
| `blue` | `accent.fg` |
| `blue_text` | `scale.blue.2` |
| `curve` | `scale.blue.3` |
| `axis` | `fg.subtle` |
| `success` | `btn.primary.bg` |
| `success_outline` | `success.fg` |
| `success_foreground` | `btn.primary.text` |
| `success_text` | `scale.green.1` |
| `warning` | `attention.fg` |
| `danger` | `danger.fg` |

上游颜色映射到宿主现有的 24 个 RGB 字段。透明背景合成后四舍五入到 8 位通道。需要宿主支持 `success_foreground` 字段；High Contrast 的成功按钮使用原版深色文字。

来源与 MIT 许可证原文随插件分发。

- https://github.com/primer/github-vscode-theme/tree/cd78e5e4e7bcf132a6f428ae0f32264bb1b729cf
- https://www.npmjs.com/package/@primer/primitives/v/7.10.0
- `LICENSES.txt`
