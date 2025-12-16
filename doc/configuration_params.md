Full list of vim-mlflow config variables that may be of interest to set in resource file:

|           variable               |               description               |
| -------------------------------- | --------------------------------------- |
| `g:mlflow_tracking_uri` _(required)_ | The MLFLOW_TRACKING_URI of the MLflow tracking server to connect to (default is `"http://localhost:5000"`)|
| `g:vim_mlflow_timeout`           | Timeout in float seconds if cannot access MLflow tracking server (default is 0.5)|
| `g:vim_mlflow_buffername`        | Buffername of the MLflow side pane (default is `__MLflow__`)|
| `g:vim_mlflow_runs_buffername`   | Buffername of the MLflowRuns side pane (default is `__MLflow__`)|
| `g:vim_mlflow_vside`             | Which side to open the MLflow pane on: 'left' or 'right' (default is `right`)|
| `g:vim_mlflow_hside`             | Whether to open the MLflowRuns pane 'below' or 'above' (default is `below`)|
| `g:vim_mlflow_width`             | Width of the vim-mlflow window in chars (default is 70)|
| `g:vim_mlflow_height`            | Width of the vim-mlflow window in chars (default is 10)|
| `g:vim_mlflow_expts_length`      | Number of expts to show in list (default is 8)|
| `g:vim_mlflow_runs_length`       | Number of runs to show in list (default is 8)|
| `g:vim_mlflow_viewtype`          | Show 1:activeonly, 2:deletedonly, or 3:all expts and runs (default is 1)|
| `g:vim_mlflow_show_scrollicons`  | Show the little up/down scroll arrows on expt/run lists, 1 or 0 (default is 1, ie yes show them)|
| `g:vim_mlflow_icon_useunicode`   | Allow unicode vs just ascii chars in UI, 1 or 0 (default is 0, ascii)|
| `g:vim_mlflow_icon_vdivider`     | Default is `'─'` if `vim_mlflow_icon_useunicode` else `'-'`|
| `g:vim_mlflow_icon_scrollstop`   | Default is `'▰'` if `vim_mlflow_icon_useunicode` else `''`|
| `g:vim_mlflow_icon_scrollup`     | Default is `'▲'` if `vim_mlflow_icon_useunicode` else `'^'`|
| `g:vim_mlflow_icon_scrolldown`   | Default is `'▼'` if `vim_mlflow_icon_useunicode` else `'v'`|
| `g:vim_mlflow_icon_markrun`      | Default is `'▶'` if `vim_mlflow_icon_useunicode` else `'>'`|
| `g:vim_mlflow_icon_hdivider`     | Default is `'│'` if `vim_mlflow_icon_useunicode` else `'|'`|
| `g:vim_mlflow_icon_plotpts`      | Default is `'●'` if `vim_mlflow_icon_useunicode` else `'*'`|
| `g:vim_mlflow_icon_between_plotpts` | Default is `'•'` if `vim_mlflow_icon_useunicode` else `'.'`|
| `g:vim_mlflow_color_titles`      | Element highlight color label (default is `'Statement'`)|
| `g:vim_mlflow_color_divlines`    | Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_scrollicons `| Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_selectedexpt`| Element highlight color label (default is `'String'`)|
| `g:vim_mlflow_color_selectedrun` | Element highlight color label (default is `'Number'`)|
| `g:vim_mlflow_color_help`        | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_color_markrun`     | Element highlight color label (default is `'vimParenSep'`)|
| `g:vim_mlflow_color_hiddencol`   | Element highlight color label (default is `'Comment'`)|
| `g:vim_mlflow_color_plot_title`  | Highlight group for plot titles (default `'Statement'`)|
| `g:vim_mlflow_color_plot_axes`   | Highlight group for plot axes text (default `'vimParenSep'`)|
| `g:vim_mlflow_color_plotpts`     | Highlight group for plot point glyphs (default `'Constant'`)|
| `g:vim_mlflow_color_between_plotpts` | Highlight group for line segments between points (default `'Comment'`)|
| `g:vim_mlflow_plot_height`       | ASCII plot height in rows when graphing metric history (default `25`)|
| `g:vim_mlflow_plot_width`        | ASCII plot width in columns (default `70`)|
| `g:vim_mlflow_plot_xaxis`        | `'step'` or `'timestamp'` for metric plot x-axis (default `'step'`)|
| `g:vim_mlflow_plot_reuse_buffer` | If `1`, reuse a single `__MLflowMetricPlot__` buffer; if `0`, create sequential plot buffers (default `1`)|
| `g:vim_mlflow_artifacts_max_depth` | Maximum artifact directory depth shown when expanding folders (default `3`)|

