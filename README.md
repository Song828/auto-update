---

## 步骤

### 1. 添加环境变量

您需要在设置中添加以下**环境变量**（可能用于 CI/CD 或其他自动化流程）：

| 变量名 | 变量值/说明 |
| :--- | :--- |
| **OPENWRT\_WEBHOOK\_SECRET** | `密钥` |
| **OPENWRT\_WEBHOOK\_URL** | `http://example.com:8888/hooks/update-smartdns-rules` |
| **UBUNTU\_WEBHOOK\_SECRET** | `密钥` |
| **UBUNTU\_WEBHOOK\_URL** | `http://example.com:8889/hooks/update-smartdns-rules` |

### 2. 复制 Webhook 文件夹

将 **`webhook`** 文件夹**复制**到本地。

---
