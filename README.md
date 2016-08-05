# Introduction

Around April 2016, the Department of Veterans Affairs released a [dataset of medical center-level mental health statistics covering fiscal year 2015.](http://catalog.data.gov/dataset/va-national-mental-health-statistics-2015) These statistics aim to shed light on the prevalence, mental health utilization, non-mental health utilization, mental health workload, and psychological testing of Veterans with a possible or confirmed diagnosis of mental illness. These data are 
prepared by the [VA Northeast Program Evaluation Center (NEPEC)](http://www.ptsd.va.gov/PTSD/about/divisions/evaluation/index.asp) which the organization responsible for evaluating VA's mental health programs. 

# Data Description

The [FY15 mental health annual datasheet](https://github.com/department-of-veterans-affairs/NEPEC_AnnualDataSheet_MH_FY15) is provided in JSON format via GitHub. [There is also data dictionary](https://github.com/department-of-veterans-affairs/NepecPtsdDataDictionary) on GitHub that gives an overview of NEPEC, defines these variables and the values they assume, along with a look-up table to link facility station numbers to their names. The data dictionary is extremely challenging to use because it encompasses multiple datasets, of inconsistent and undefined terminology, and is structured in a way that is counter to being machine readable. In order to easily pull-in the useful bits of the data dictionary into the Shiny application I had to manually re-create parts of the data dictionary (NepecPtsdDataDictionary-Edit.csv). These steps are outlined below in as much detail as possible, I have also included the original data dictionary (NepecPtsdDataDictionary.xlsx) in this repository for the sake of posterity. But before delving into the data dictionary challenges, I will provide an overview of the dataset itself.

There are 5,182 observations in this dataset and it consists of five variables: Category, Item, Station, Value, and ValueType. All of these variable are read-in as character types including the *Value* field which has % signs for some observations. 

# Data Preparation Steps 

1. Created a custom data dictionary. I needed to create a custom data dictionary due to the reasons mentioned above so that I could pull- definition into the Shiny application. All of the issues in the data dictionary and the remediation steps are described in detail below:

    **Issue 1** - The *Item* field in the dataset contains each measure, however, the data dictionary the term *Element* is used. These have been linked in the custom data dictionary. 

    **Issue 2** - Some of the *Elements* are grouped under a heading in the data dictionary. The verbiage of these headings is fused with the *Element* verbiage in the Item field of the dataset. For example, in the image below, on row 46 you can see the heading *Proportion of Veterans with Possible Mental Illness Seen in:*. Under this heading there are five *Elements*, however, in the dataset in the *Item* field you will see *Proportion of Veterans with Possible Mental Illness Seen in Any Mental Health*. To address this issue I had manually concatenated these terms so that I could link the *Item* values to its corresponding definitions. In the edited data dictionary I called the *Element* headings *ItemPrefix*.

    ![](images/Item_Element_Grouping.PNG)
    \newline

    **Issue 3** - Relationship between *Category* and *Item* is not described in the data dictionary nor are the *Category* values defined. I dealt with this by extracting the unique *Category-Item* combinations from the dataset and added them to the data dictionary. I did not attempt to get *Category* definitions. 

    **Issue 4** - In the above image you will also notice that there is a blank column (colored black) and a blank cell next to each *Element* heading. These were obviously not replicated in the custom data dictionary. 

    **Recap** - The custom data dictionary maps the following relationship:

    Item (dataset) - Category (dataset) - ItemPrefix (dictionary) - Element (dictionary) - Definition (dictionary)

2. Added *VISN* and *Station.Name* to the mental health dataset.

3. Removed % sign from *Value* field and converted to numeric data type.

4. Save dataset as *.rds for Shiny application. 