# RescueNet — Setup Guide

## Create 3 Collections in Appwrite Dashboard

Go to: Appwrite Console → Database `69e916610024758bfa45` → Create Collection

### 1. Collection: `disasters`
Set Collection ID to: `disasters`

| Attribute | Type | Required |
|---|---|---|
| userId | String (256) | Yes |
| title | String (256) | Yes |
| type | String (64) | Yes |
| severity | String (32) | Yes |
| description | String (5000) | Yes |
| locationName | String (512) | Yes |
| latitude | Float | No |
| longitude | Float | No |
| status | String (32) | Yes |
| photoUrl | String (512) | No |
| affectedCount | Integer | No |

**Permissions**: All Users → Create, Read, Update, Delete

### 2. Collection: `resources`
Set Collection ID to: `resources`

| Attribute | Type | Required |
|---|---|---|
| disasterId | String (256) | Yes |
| userId | String (256) | Yes |
| type | String (64) | Yes |
| quantity | Integer | No |
| status | String (32) | Yes |
| notes | String (1024) | No |

**Permissions**: All Users → Create, Read, Update, Delete

### 3. Collection: `volunteers`
Set Collection ID to: `volunteers`

| Attribute | Type | Required |
|---|---|---|
| userId | String (256) | Yes |
| fullName | String (256) | Yes |
| phone | String (64) | Yes |
| skills | String (512) | Yes |
| isAvailable | Boolean | No |
| assignedDisasterId | String (256) | No |

**Permissions**: All Users → Create, Read, Update, Delete

## Run the App
```bash
cd D:\MyNest\disaster_response
flutter run
```
