# Legal Document Request Automation - Make Scenario

## Overview
This Make (formerly Integromat) scenario automates the legal document request workflow by triggering when a new entry is added to Google Sheets, fetching and populating legal document templates, and sending them to clients via email while logging all activities to a database.

**Execution Schedule**: Every 15 minutes (configurable)  
**Average Processing Time**: 5-8 seconds per document  
**Operations per Document**: ~6-7 operations

## Workflow Diagram

```
Google Sheets (Watch New Rows)
        ↓
Tools (Set Variables)
        ↓
Router (Route by Document Type)  And PostgreSQL (Execute Query - Insert Record)
        ↓
Google Drive (Search for Template Folder)
        ↓
Router (Process Document)
        ↓
Google Docs (Create Document from Template)
        ↓
Google Drive (Download as PDF)
        ↓
Gmail (Send Email)
        ↓
PostgreSQL (Execute Query - Update Status)
```

## Prerequisites

### Required Integrations
1. **Google Sheets** - For trigger data
2. **Google Drive** - For template storage and document management
3. **Google Docs** - For populating document templates
4. **Gmail** - For sending documents to clients
5. **PostgreSQL** - For logging requests

### Required Accounts/Access
- Google Workspace account with access to:
  - Google Sheets
  - Google Drive
  - Gmail
- Make.com account (Free or paid tier)
- PostgreSQL database (hosted or local)

## Setup Instructions

### 1. Prepare Google Sheets Trigger

1. Create a new Google Sheet with the following columns:
   - **Column A**: `Client Name`
   - **Column B**: `Case Type`
   - **Column C**: `Email`
   - **Column D**: `Document Type Requested`

2. Share the sheet with your Make service account or ensure proper OAuth permissions

### 2. Organize Google Drive Templates

1. Create a folder structure in Google Drive:
   ```
   Legal Document Automation/
   ├── Templates/
   │   ├── Contract Template
   │   ├── Agreement Template
   │   ├── NDA Template
   │   └── Power of Attorney Template
   └── Processed Documents/
       └── [Auto-generated folders by case]
   ```

2. Prepare document templates with placeholders:
   - Use `{{CLIENT_NAME}}` for client name
   - Use `{{CASE_TYPE}}` for case type
   - Use `{{DATE}}` for current date (optional)

### 3. Setup Database

#### PostgreSQL Setup

```sql
CREATE TABLE IF NOT EXISTS legal_document_requests (
    id VARCHAR(255) PRIMARY KEY NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    case_type VARCHAR(255) NOT NULL,
    document_type VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_client_name ON legal_document_requests(client_name);
CREATE INDEX idx_timestamp ON legal_document_requests(timestamp);
CREATE INDEX idx_status ON legal_document_requests(status);
```

### 4. Create Make Scenario

#### Step 1: Add Google Sheets Trigger
1. In Make, create a new scenario
2. Add **Google Sheets > Watch New Rows** module
3. Configure:
   - **Spreadsheet**: Select your Google Sheet
   - **Sheet**: Select the sheet name
   - **Limit**: 1 (process one row at a time)
4. Map the columns to variables:
   - `Client Name` → Column A
   - `Case Type` → Column B
   - `Email` → Column C
   - `Document Type Requested` → Column D

#### Step 2: Set Variables (Tools Module)
1. Add **Tools > Set Variable** module
2. Configure variables for easier reference:
   - Variable name: `id` → Value: `uuid()`

#### Step 3: Add Router for Document Type
1. Add **Router** module
2. This allows inserting into Postgres tables
3. Set up to search for Google drive 

#### Step 4.1: Log to Database (Insert)
1. Add **PostgreSQL > Execute a Query (advanced)** module
2. Configure:
   - **Connection**: Your database connection
   - **SQL Query**:
     ```sql
     INSERT INTO legal_document_requests (id, client_name, case_type, document_type, status)
     VALUES ($1, $2, $3, $4, "Request Received")
     ```
   - **Parameters**:
     - `$1`: `{{6.id}}` (document ID)
     - `$2`: `{{2.clientName}}`
     - `$3`: `{{2.caseType}}`
     - `$4`: `{{2.documentType}}`
     - `$5`: `'Request Received'`

#### Step 4.2: Search for Template in Google Drive
1. Add **Google Drive > Search for Files/Folders** module
2. Configure:
   - **Search Query**: `name contains "{{2.documentType}}" and mimeType = "application/vnd.google-apps.document"`
   - **Folder**: Select your "Templates" folder
   - **Limit**: 1

#### Step 5: Add Second Router (Optional)
1. Add another **Router** module for processing logic
2. This will handle success/error paths or different processing based on template found/not found

#### Step 5.1: Update Status
1. Add another **PostgreSQL > Execute a Query (advanced)** module
2. Configure:
   - **SQL Query**:
     ```sql
     UPDATE legal_document_requests 
     SET status = 'Template Not Found' 
     WHERE id = $1
     ```
   - **Parameters**:
     - `$1`: `{{6.id}}`


#### Step 5.2: Send Email via Gmail to Make Owner
1. Add **Gmail > Send an Email** module
2. Configure:
   - **To**: `{{2.clientEmail}}`
   - **Subject**: `Your Requested Legal Document - {{2.documentType}} Not Found`
   - **Content**: 
     ```
     Dear User
     Client - {{2.clientName}} has requested {{2.documentType}} which is not available in inventory.

     Regards,
     ```

#### Step 6: Create Document from Template
1. Add **Google Docs > Create a Document from a Template** module
2. Configure:
   - **Template Document ID**: `{{4.id}}` (from search results)
   - **New Document Name**: `{{2.documentType}} - {{2.clientName}}`
   - **Destination Folder**: Select "Processed Documents" folder
   - **Replace Variables**:
     - `{{CLIENT_NAME}}` → `{{2.clientName}}`
     - `{{CASE_TYPE}}` → `{{2.caseType}}`
     - `{{DATE}}` → `{{formatDate(now; "MMMM DD, YYYY")}}`

#### Step 7: Download Document
1. Add **Google Drive > Download a File** module
2. Configure:
   - **File ID**: `{{6.id}}` (from created document)

#### Step 8: Send Email via Gmail
1. Add **Gmail > Send an Email** module
2. Configure:
   - **To**: `{{2.clientEmail}}`
   - **Subject**: `Your Requested Legal Document - {{2.documentType}}`
   - **Content**: 
     ```
     Dear {{2.clientName}},

     Please find attached your requested legal document for your {{2.caseType}} case.

     If you have any questions or need any modifications, please don't hesitate to contact us.

     Best regards,
     [Your Law Firm Name]
     ```
   - **Attachments**: Map from Step 7 (PDF file data)
   - **From Name**: Your Law Firm Name


#### Step 9: Update Status
1. Add another **PostgreSQL > Execute a Query (advanced)** module
2. Configure:
   - **SQL Query**:
     ```sql
     UPDATE legal_document_requests 
     SET status = 'Request Completed' 
     WHERE id = $1
     ```
   - **Parameters**:
     - `$1`: `{{6.id}}`


## Scenario Summary

### Modules Used (10 total)
1. **Google Sheets** - Watch New Rows (Trigger)
2. **Tools** - Set Variable (Data preparation)
3. **Router** - Route by document type
4. **Google Drive** - Search for Files/Folders
5. **Router** - Process logic
6. **Google Docs** - Create Document from Template
7. **Google Drive** - Download as PDF
8. **Gmail** - Send Email
9. **PostgreSQL** - Execute Query (Insert)
10. **PostgreSQL** - Execute Query (Update)