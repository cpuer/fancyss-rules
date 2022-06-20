## 使用GitHub Actions每日自动更新[fancyss 3.0](https://github.com/hq450/fancyss/tree/3.0/rules)规则  
[![Update Fancyss Rules](https://github.com/cpuer/fancyss-rules/actions/workflows/rules.yml/badge.svg)](https://github.com/cpuer/fancyss-rules/actions/workflows/rules.yml)

---   
#### Actions会在每日UTC+8 3:45时自动执行并更新规则，推荐在插件中设置每天4:00定时更新  
---
### 食用方法：
- 进入路由器SSH，运行以下命令会自动将`ss_rule_update.sh`脚本中的`url_main`参数指向我的仓库：
- `sed -i 's/^\turl_main.*/\turl_main="https:\/\/raw.githubusercontent.com\/cpuer\/fancyss-rules\/main\/rules"/g' /koolshare/scripts/ss_rule_update.sh`  （**推荐**，直连GitHub仓库）
### 每次fancyss插件更新后都需要\*重新运行一次\*更新`ss_rule_update`脚本的命令
