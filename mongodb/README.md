# MongoDB

Installs MongoDB and the PHP MongoDB extension.

## Supported Ubuntu Versions

| Ubuntu Version | Codename | MongoDB Version | Shell Command |
|----------------|----------|-----------------|---------------|
| 14.04 LTS      | trusty   | 3.4             | `mongo`       |
| 16.04 LTS      | xenial   | 4.4             | `mongo`       |
| 18.04 LTS      | bionic   | 4.4             | `mongo`       |
| 20.04 LTS      | focal    | 4.4             | `mongo`       |
| 22.04 LTS      | jammy    | 4.4             | `mongo`       |
| 24.04 LTS      | noble    | 8.0             | `mongosh`     |

## Notes

- MongoDB 8.0 is the first version with official Ubuntu 24.04 (Noble) support
- MongoDB 8.0 uses `mongosh` instead of the legacy `mongo` shell
- XHGui requires MongoDB 3.2+, so all supported versions are compatible
