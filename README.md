
### **Clinical Trial Safety Analysis – DM & AE (Base SAS + PROC SQL)**

---

### 🧪 Project Overview

This project demonstrates an **end-to-end clinical trial safety analysis** using **Demographics (DM)** and **Adverse Events (AE)** datasets, implemented in **Base SAS and PROC SQL**.
The workflow follows **industry-aligned clinical data practices**, including data cleaning, validation, reconciliation, summary reporting, and safety listings.

The final output includes a **PDF Safety Report** and multiple **analysis-ready datasets**, similar to what is expected in **clinical research, CROs, and pharma environments**.

---

### 📂 Datasets Used

* **DM (Demographics)**

  * Subject-level information (USUBJID, AGE, SEX, ARM, COUNTRY)
* **AE (Adverse Events)**

  * Event-level safety data (AEDECOD, AESTDTC, AEENDTC, AESER, SEVERITY)

📌 Input format: **Excel (.xls)**
📌 Data imported using `PROC IMPORT`

---

### ⚙️ Tools & Technologies

* **Base SAS**
* **PROC SQL**
* **ODS PDF Reporting**
* **Clinical Safety Analysis Concepts**
* **CDISC-style subject reconciliation logic**

---

### 🛠️ Key Tasks & Deliverables

#### **1. Data Import & Inspection**

* Imported DM and AE datasets from Excel
* Sorted by `USUBJID`
* Reviewed structure using `PROC CONTENTS`

---

#### **2. Data Cleaning & Validation**

Performed key clinical data checks:

* Missing **AEDECOD**
* AE start date later than end date
* Subjects aged **< 18 years** (protocol deviation)
* Duplicate AEs (`USUBJID + AEDECOD + AESTDTC`)
* Missing critical variables:

  * AESTDTC
  * AEENDTC
  * AESER
  * SEVERITY

📄 **Output:** Data discrepancy listings

---

#### **3. Subject Reconciliation (DM vs AE)**

* Subjects in AE but not in DM
* Subjects in DM with no AEs
* Count of subjects in each dataset

📄 **Output:** Reconciliation tables and listings

---

#### **4. Adverse Event Summary**

**Subject-Level**

* Total subjects
* Subjects with ≥1 AE
* Percentage of subjects with AEs

**Event-Level**

* Total AEs
* Total Serious AEs (AESER = Yes)
* Total Severe AEs (SEVERITY = Severe)
* AE counts by Preferred Term
* AE counts by Severity

---

#### **5. AE Incidence by Treatment Arm**

Generated AE incidence table per ARM:
| ARM | Total Subjects | Subjects with ≥1 AE | % Subjects with AE |

📄 Created using **PROC SQL joins**

---

#### **6. Serious AE Listing**

* Filtered AESER = Yes
* Sorted by USUBJID and Start Date
* Included:

  * USUBJID
  * AEDECOD
  * SEVERITY
  * Start/End Dates

---

#### **7. Country-wise AE Distribution**

* Merged DM + AE datasets
* Generated AE frequency by **Country**

---

#### **8. Final Safety Analysis Dataset**

Created **AE_SUMMARY** dataset containing:

* USUBJID
* AGE
* SEX
* ARM
* Total AEs
* Serious AEs
* Severe AEs

📄 Analysis-ready dataset for reporting or TLF generation

---

#### **Bonus: Advanced SAS Techniques**

* Ranked **Top Most Frequent AEs**
* Used `PROC RANK` for dense ranking
* Built a **macro-driven AE listing** by Treatment Arm:

  * DRUG_A
  * DRUG_B
  * PLACEBO
* Standardized ARM values programmatically

---

### 📊 Output

* 📄 **Safety_Report.pdf** (ODS PDF)
* 📁 Cleaned AE datasets
* 📁 Reconciliation tables
* 📁 Final AE_SUMMARY dataset
* 📁 Treatment-arm specific AE listings

---

### 🎯 Key Skills Demonstrated

* Clinical safety data handling
* AE reconciliation logic
* SAS reporting (ODS PDF)
* PROC SQL joins & aggregations
* Data validation aligned with clinical protocols
* Macro programming for automation

---

### 📌 Ideal For

* Clinical Data Analyst
* Clinical SAS Programmer (Entry–Mid)
* Pharmacovigilance & Safety Analytics
* CRO / Pharma interview portfolio

---

### 🔗 How to Use

1. Update file paths for local system
2. Ensure Excel dataset structure matches DM & AE sheets
3. Run the `.sas` program end-to-end
4. Review generated PDF and datasets

---

### 🙌 Author

**Kavin Raj S A**
M.Tech – Computational Biology
Clinical Data Analytics | SAS | Safety Analysis
