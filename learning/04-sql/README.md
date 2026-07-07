# Exercise 04 - Azure SQL Database

## Architecture

Terraform deploys:

- Resource Group
- App Service Plan
- App Service
- Storage Account
- Azure SQL Server
- Azure SQL Database

---

## Manual Steps

### Resource Group
- ✅ None

---

### App Service Plan
- ✅ None

---

### App Service

- [ ] Deploy application code
- [ ] Configure Startup Command
  ```
  gunicorn --bind=0.0.0.0:8000 app:app
  ```
- [ ] Configure Environment Variables
  - Storage Connection String
  - SQL Server
  - SQL Database
  - SQL Username
  - SQL Password

---

### Storage Account

- [ ] Retrieve Storage Connection String
- [ ] Upload Blob content
  - images/
  - data/
  - text/

---

### Azure SQL Server

- [ ] Add client public IP to Firewall
- [ ] Allow Azure services (if required)

---

### Azure SQL Database

- [ ] Create tables
- [ ] Insert sample data

---

## Application

The Flask application should display:

- Hello Azure!
- Data from Blob Storage
- Images from Blob Storage
- Text from Blob Storage
- Messages from Azure SQL Database

---

## Future Automation (Exercise 03.5)

GitHub Actions will automate:

- Application deployment
- Blob content upload
- Database schema deployment
- Sample data insertion

Terraform will automate:

- All Azure infrastructure
