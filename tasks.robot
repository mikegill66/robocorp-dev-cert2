*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 This is for the Robocorp level 2 certification exam.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             Collections
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${URL_CSV}          https://robotsparebinindustries.com/orders.csv
${URL_WEBSITE}      https://robotsparebinindustries.com/#/robot-order
${DOWNLOAD_FILE}    ${OUTPUT_DIR}${/}orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders} =    Get orders
    ${row_cnt}    ${EMPTY} =    Get Table Dimensions    ${orders}

    FOR    ${x}    IN RANGE    ${row_cnt}
        &{row} =    Get Table Row    ${orders}    ${x}
        Close the annoying modal
        Fill the form    &{row}
        ${order_num} =    Get From Dictionary    ${row}    Order number
        Download and store receipt    ${order_num}
        Order another robot
    END

    Archive output PDFs
    Log    Done.
    [Teardown]    RPA.Browser.Selenium.Close Browser


*** Keywords ***
Open the robot order website
    RPA.Browser.Selenium.Open Available Browser    ${URL_WEBSITE}

Get Orders
    RPA.HTTP.Download
    ...    url=${URL_CSV}
    ...    target_file=${DOWNLOAD_FILE}
    ...    overwrite=True
    ${order_table} =    RPA.Tables.Read table from CSV    ${DOWNLOAD_FILE}    header=True
    RETURN    ${order_table}

Close the annoying modal
    ${button_xpath} =    Set Variable    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[3]
    RPA.Browser.Selenium.Click Element    ${button_xpath}

Fill the form
    [Arguments]    &{order}
    ${order_num} =    Get From Dictionary    ${order}    Order number
    ${order_head} =    Get From Dictionary    ${order}    Head
    ${order_body} =    Get From Dictionary    ${order}    Body
    ${order_legs} =    Get From Dictionary    ${order}    Legs
    ${order_addr} =    Get From Dictionary    ${order}    Address

    ${xpath_head} =    Set Variable    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[1]/select
    RPA.Browser.Selenium.Select From List By Value    ${xpath_head}    ${order_head}

    RPA.Browser.Selenium.Select Radio Button    body    ${order_body}

    ${xpath_legs} =    Set Variable    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    RPA.Browser.Selenium.Input Text    ${xpath_legs}    ${order_legs}

    ${xpath_addr} =    Set Variable    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input
    RPA.Browser.Selenium.Input Text    ${xpath_addr}    ${order_addr}

    ${loc_preview} =    Set Variable    id:preview
    RPA.Browser.Selenium.Click Button    ${loc_preview}

    Wait Until Keyword Succeeds    5x    3s    Place order

Place order
    ${loc_order} =    Set Variable    id:order
    RPA.Browser.Selenium.Click Button    ${loc_order}
    RPA.Browser.Selenium.Element Should Be Visible    id:receipt

Download and store receipt
    [Arguments]    ${order_num}
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:receipt

    ${receipt_html} =    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    #${temp_pdf} =    Set Variable    ${OUTPUT_DIR}${/}${order_num}.pdf
    ${receipt_pdf} =    Set Variable    ${OUTPUT_DIR}${/}order_num_${order_num}.pdf
    RPA.PDF.Html To Pdf    ${receipt_html}    ${receipt_pdf}

    ${image_file} =    Set Variable    ${OUTPUT_DIR}${/}${order_num}.png
    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    ${image_file}

    ${files} =    Create List
    ...    ${image_file}

    #RPA.PDF.Open Pdf    ${receipt_pdf}
    RPA.PDF.Add Files To PDF    ${files}    ${receipt_pdf}    append=${True}
    RPA.PDF.Close All Pdfs

    #RPA.FileSystem.Remove File    ${temp_pdf}
    RPA.FileSystem.Remove File    ${image_file}

Order another robot
    ${loc_another} =    Set Variable    id:order-another
    RPA.Browser.Selenium.Wait Until Page Contains Element    ${loc_another}
    RPA.Browser.Selenium.Click Button    ${loc_another}

Archive output PDFs
    ${zip_file} =    Set Variable    ${OUTPUT_DIR}${/}robot_order.zip
    RPA.FileSystem.Remove File    ${zip_file}
    RPA.Archive.Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file}    include=*.pdf

    ${files} =    RPA.FileSystem.List files in directory    ${OUTPUT_DIR}
    FOR    ${file}    IN    @{files}
        ${file_ext} =    RPA.FileSystem.Get File Extension    ${file}
        ${pdf_ext} =    Set Variable    .pdf

        IF    "${file_ext}" == "${pdf_ext}"
            RPA.FileSystem.Remove File    ${file}
        END
    END

#teardown - Close RobotSpareBin Browser
