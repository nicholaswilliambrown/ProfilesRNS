
function getPersonUriFromLabel() {
    let result = "";

    if (gMapTab.label) {
        gMapTab.label.PreferredPath;
    }
    return result;
}
function trySearchUrlParam(key) {
    let url = new URL(window.location.href);
    let result = decodeURIComponent(url.searchParams.get(key));

    // um...
    if (result == 'null') result = '';

    return result;
}
function tryMatchUrlParam(regex) {
    // returns $1 from regex, so make sure to set up for $1
    let wSearch = window.location.search;
    let match = wSearch.match(regex);

    let result = match ? match[1] : "";
    return result;
}
function tryMatchPathParam(regex) {
    // todo: use tryMatchUrlParam instead!!!
    // returns $1 from regex, so make sure to set up for $1
    let wSearch = window.location.href;
    let match = wSearch.match(regex);

    let result = match ? match[1] : "";
    return result;
}
function stringifyJson(json) {
    return JSON.stringify(json, null, 2);
}
function displayJsonFragment(target, json) {
    let diagnostic = $(`<div>${stringifyJson(json).substring(0,150) + ". . ."}</div>`);
    target.append(diagnostic);
}
function dynamicGetWidth(text, tempTarget) {
    // you don't get width until you are plugged into DOM
    let span = $(`<span>${text}</span>`);
    tempTarget.append(span);

    let result = span.width();
    span.detach(); // stop exploiting tempTarget

    return result;
}
function ellipsizeToFit(text, target, extraWidth) {
    let result = text;

    let targetWidth = target.width();

    let dotsWidth = dynamicGetWidth('...', target);
    let textWidth = dynamicGetWidth(text, target);

    if (textWidth + extraWidth > targetWidth) {
        while (textWidth + extraWidth + dotsWidth > targetWidth) {
            text = text.substring(0, text.length - 1);
            textWidth = dynamicGetWidth(text, target);
        }
        result = text + "...";
    }
    return result;
}
// capitalize
function initialCapital(input) {
    return input.charAt(0).toUpperCase() + input.substring(1);
}
function dateStringToDate(dateString) {
    let date = new Date(dateString);
    return date;
}
function dateToNumsYMD(date) {
    let year = date.getFullYear();
    let month = date.getMonth();
    let day = date.getDate();

    let result = [year, month, day];
    // zero-index
    day++;

    return result;
}
function dateStringToMDY_strings(dateString) {
    let date = dateStringToDate(dateString);
    let [year, month, day] = dateToNumsYMD(date);

    // second row of monthNames
    month = gCommon.monthNames[month + 12];

    let result = `${month} ${day}, ${year}`;
    return result;
}
function dateStringToMDY_nums(dateString) {
    let date = dateStringToDate(dateString);
    let [year, month, day] = dateToNumsYMD(date);

    // zero offset
    month++;

    let result = `${pad(month, 2)}/${pad(day, 2)}/${year.toString().replace(/^../, "")}`;
    return result;
}
function orEmptyList(input) {
    let result = [];
    if (input && input.length) {
        result = input;
    }
    return result;
}
function orBlank(input) {
    return orNA(input, "");
}
function orNA(input, na) {
    let result = na;
    if (input) {
        result = input;
    }
    return result;
}
function orNaPropertyList(object, property) {
    return orNaProperty(object, property, []);
}
function orNaProperty(object, property, na) {
    if (!na) {
        na = gCommon.NA;
    }
    let result = na;
    if (object && property && object[property]) {
        result = object[property];
    }
    return result;
}
function toSession(key, object, useLocal) {
    let session = useLocal ? localStorage : sessionStorage;

    let stringy = JSON.stringify(object);
    session.setItem(key, stringy);
}
function fromSession(key, useLocal) {
    let session = useLocal ? localStorage : sessionStorage;
    let stringy = session.getItem(key);

    let result = JSON.parse(stringy);
    return result;
}

// https://stackoverflow.com/questions/33289726/combination-of-async-function-await-settimeout
function waitableTimeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
// useful when combining parts of Url's
function undoubleTheSlash(url) {
    return url.replaceAll("//", "/")
}
function isArray(obj) {
    return $.isArray(obj);
}
function pad(num, size) {
    num = num.toString();
    while (num.length < size) num = "0" + num;
    return num;
}
function underSpace(input) {
    return input.replace(/\s/g, "_");
}
function addMentorModulesForPerson() {
    // apply in profile.js at end
    g.pageJSON.push(
        {
            DisplayModule: 'Person.CurrentStudentOpportunities',
            ModuleData: [
                {
                    StudentOpportunityId                      : 118,
                    Title                                     : "Hypertension & Blood Pressure",
                    StartDate                                 : "2021-10-01T00:00:00",
                    EndDate                                   : "2026-06-30T00:00:00",
                    Description                               : "Hypertension affects 85% of older adults. Many have blood pressure that differ at home from clinic. Our AHA-certified hypertension clinic is one of the only hypertension centers of excellence in the country that performs 24-hour ambulatory blood pressure monitoring. We are conducting a number of innovative quality improvement projects focused on improved blood pressure measurement in the clinic setting, including home blood pressure monitoring and automated office-based blood pressure monitoring. We are also creating a registry of ambulatory blood pressure measurements, which will be used to characterize blood pressure variability at home in a wide range of general medicine patients, yielding novel and previously uncharacterized insights on blood pressure regulation in a number of understudied populations.   This experience provides students opportunities to: \n(1) Learn the process of registry creation in the context of clinical practice for rigorous quality improvement projects \n(2) Participate in publications related to blood pressure measurement and hypertension diagnosis at home and in clinic \n(3) Collaborate with clinics throughout Harvard (and eventually nationally outside Harvard) to grow the registry \n(4) Work with an innovative team to improve the technologic implementation of blue-tooth enabled home blood pressure monitors in clinical practice"
                },
                {
                    StudentOpportunityId                      : 120,
                    Title                                     : "DASH Groceries for Urban Food Deserts",
                    StartDate                                 : "2021-10-01T00:00:00",
                    EndDate                                   : "2026-09-30T00:00:00",
                    Description                               : "High blood pressure affects nearly 50% of adults in the US. Access to healthful foods is a critical barrier to preventive efforts to prevent hypertension and cardiovascular disease. We are conducting two randomized clinical trials to deliver groceries to Black adults living in Boston food deserts. We will recruit participants through 3 Beth Israel Clinics. Our primary outcome will be blood pressure.  This experience provides students opportunities to:  \n(1) Learn about clinical trial implementation and would emerge with knowledge on how to conduct trials; \n(2) Participate in the publications related nutrition, health access, and blood pressure using data sets including NHANES as well as prior clinical trials. \n(3) Participate in planning novel nutrition interventions involving HUD and other government subsidized meal programs \n(4) Network with institutions throughout the U.S. as part of an American Heart Association Strategic Network focused on health equity"
                },
                {
                    StudentOpportunityId                      : 600,
                    Title                                     : "Equitable Recruitment of Underrepresented Groups into Cardiovascular Trials",
                    StartDate                                 : "2023-02-01T00:00:00",
                    EndDate                                   : "2027-12-31T00:00:00",
                    Description                               : "We are funded by the American Heart Association as part of a Strategically Focused Research Network (SFRN) focused on improving diversity and representation in clinical trials. We are working with a national team of investigators from University of Vermont and Johns Hopkins University to study strategies for improving outreach and enrollment of underrepresented communities. Our team is multidisciplinary and includes cardiologists, general internists, ethicists, computer scientists, and nursing. Students have the opportunity to participate in the design of novel recruitment experiments as well as lead research for presentation at conferences and publication. Through this opportunity students will gain experience in clinical trials, clinical trial recruitment, primary data collection, and experience in scientific data interpretation and communication. Moreover, there are amble opportunities for expanding professional networks through working in a national network. We have an excellent track record of mentorship with students and would be delighted to have you join our team!"
                }
            ]
        });
    g.pageJSON.push(
        {
            DisplayModule: 'Person.CompletedStudentProjects',
            ModuleData:
                [
                    {
                        projecttitle: "Child Mental Health and Health Delivery in Western Aceh, Indonesia",
                        ProgramType: "International",
                        ResearchStart: "2008-03-31T00:00:00",
                        ResearchEnd: "2008-04-26T00:00:00"
                    },
                    {
                        projecttitle: "Promoting Maternal Health in Rural Indonesia",
                        ProgramType: "International",
                        ResearchStart: "2008-01-26T00:00:00",
                        ResearchEnd: "2008-02-29T00:00:00"
                    },
                    {
                        projecttitle: "Getting from here to care:  The potential of bicycles to improve health care delivery in Kisumu, Kenya",
                        ProgramType: "International",
                        ResearchStart: "2010-06-14T00:00:00",
                        ResearchEnd: "2010-08-06T00:00:00"
                    },
                    {
                        projecttitle: "Evaluating Child Mental Health and Health Care Delivery in Aceh, Indonesia",
                        ProgramType: "International",
                        ResearchStart: "2008-03-30T00:00:00",
                        ResearchEnd: "2008-04-26T00:00:00"
                    },
                    {
                        projecttitle: "WHO Call for Innovative Technologies that Address Global Health Concerns",
                        ProgramType: "International",
                        ResearchStart: "2010-06-19T00:00:00",
                        ResearchEnd: "2010-08-15T00:00:00"
                    }
                ]
        });
}

let captchaKey = 'captchad';
function clearCaptchad() {
    toSession(captchaKey, null);
}
async function captchavate(captchaSuccessFn) {
    if (fromSession(captchaKey)) {
        if (captchaSuccessFn) return captchaSuccessFn();
    }
    else {
        let moveableContentDiv = $('#moveableContentDiv');
        let inviteLoginDiv = $('#inviteLoginDiv');
        let captchaDiv = $(`<div class="myCaptcha ms-5 mt-5 bold-ish">
                                    <div class="mb-4">To load this page please verify that you are not a robot.
                                    <div class="mt-4">
                                        <table>
                                            <tr>
                                                <td class="pb-1">Verify you are human</td>
                                                <td class="ps-2"><input type="checkbox" id="captchaCheck" /></td>
                                            </tr>
                                        </table>
                                    </div>
                                </div>`);

        moveableContentDiv.hide();
        inviteLoginDiv.hide();
        $('#mainDiv').append(captchaDiv);

        $('#captchaCheck').on('click', function () {
            captchaDiv.remove();
            moveableContentDiv.show();
            inviteLoginDiv.show();

            toSession(captchaKey, "true");
            if (captchaSuccessFn) return captchaSuccessFn();
        });
    }
    return; // good for breakpoint
}
function arrayAverage(array, longwoodDefault) {
    let result = longwoodDefault;

    if (array && Array.isArray(array) && array.length) {
        result = array.reduce((a, b) => Number(a) + Number(b)) / array.length;
    }
    return result;
}
function localOnlyEvent(e) {
    e.preventDefault();
    e.stopPropagation();
}

class RowishTable {
    constructor(target, id, label) {
        this.id = id;
        this.defaultRowClass = "d-block d-md-table-row mb-4"

        this.table = $(`
                <table id="${id}" class="table d-block d-md-table" role="grid" aria-label="${label}">
                </table>`);
        this.defaultHeaderClass = "d-none d-md-block d-md-table-row";
                    // <thead class="d-block d-md-table-header-group">
                    // <tr role="row" class="d-none d-md-block d-md-table-row">
                    //     <!-- scope="col" remains active and valid for desktop view -->
                    //     <th class="noBorder" scope="col" role="columnheader">Employee Name</th>
                    //     <th class="noBorder" scope="col" role="columnheader">Role</th>
                    //     <th class="noBorder" scope="col" role="columnheader">Department</th>
                    // </tr>
                    // </thead>
                    //
                    // <tbody class="d-block d-md-table-row-group">
                    // <!-- Each row becomes a block container on mobile -->
                    // <tr class="d-block d-md-table-row mb-4" role="row">
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Name" tabindex="0">
                    //         <strong class="d-inline d-md-none">Name: </strong>bbb Morgan
                    //     </td>
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Role" tabindex="-1">
                    //         <strong class="d-inline d-md-none">Role: </strong>bbb Developer
                    //     </td>
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Department" tabindex="-1">
                    //         <strong class="d-inline d-md-none">Department: </strong>bbbb Engineering
                    //     </td>
                    // </tr>
                    // <tr class="d-block d-md-table-row mb-4" role="row">
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Name" tabindex="0">
                    //         <strong class="d-inline d-md-none">Name: </strong>Alex Morgan
                    //     </td>
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Role" tabindex="-1">
                    //         <strong class="d-inline d-md-none">Role: </strong>Developer
                    //     </td>
                    //     <td class="d-block d-md-table-cell" role="gridcell" data-label="Department" tabindex="-1">
                    //         <strong class="d-inline d-md-none">Department: </strong>Engineering
                    //     </td>
                    // </tr>
                    // </tbody>
        target.append(this.table);
    }
    emitHeader(columnSpecArray, rowClass) {
        this.emitHelper(columnSpecArray, true, rowClass);
    }
    emitRow(columnSpecArray, rowClass) {

    }
    emitHelper(columnSpecArray, isHeader, rowClass) {
        rowClass =  rowClass ?
                    rowClass : '';
        let classAttr = rowClass ? `class=${rowClass}` : '';
        let tdOrTh =        isHeader ? 'th' : 'td';
        let blockOrNone =   isHeader ? "d-none d-md-block" : "d-block";
        let roleAttr =      isHeader ? 'role="columnheader"' : 'role="gridcell"';
        let scopeAttr =     isHeader ? 'scope="col"' : "";

        let row = $(`<tr id="${this.id}Row" ${classAttr} role="row"</tr>`);
        <!-- Each row becomes a block container on mobile -->

        for (let i = 0; i < columnSpecArray.length; i++) {
            let colSpec = columnSpecArray[i];
            let col = $(`<${tdOrTh} id="${this.id}Col${i}" class="${blockOrNone} ${colSpec.classes}" ${scopeAttr} ${roleAttr}></${tdOrTh}>`);
            col.append(colSpec.value)
            row.append(col);
        }
        let rowOrHead;
        if (isHeader) {
            rowOrHead = $(`<thead class="d-block d-md-table-header-group">
                            </thead>`);
            rowOrHead.append(row);
        }
        else {
            rowOrHead = row;
        }

        this.table.append(rowOrHead);
        return rowOrHead; // may be useful in caller
    }
    addListeners() {
        const table = document.getElementById(this.id);
        const cells = Array.from(table.querySelectorAll('td'));
        const numCells = cells.length;
        const numCols = Array.from(table.querySelectorAll('th')).length;
        console.log('How many columns: ', numCols);
        console.log('How many cells: ', numCells);

        table.addEventListener('keydown', (event) => {
            const active = document.activeElement;
            if (!cells.includes(active)) return;

            const currentIdx = cells.indexOf(active);
            let targetCell = null;

            switch (event.key) {
                case 'Tab':
                    if (event.shiftKey) {
                        targetCell = cells[(currentIdx - 1 + numCells) % numCells];
                    }
                    else {
                        targetCell = cells[(currentIdx + 1) % numCells];
                    }
                    break;
                case 'ArrowRight':
                    // Move to the next cell in the entire table, wrapping to the next row automatically
                    targetCell = cells[(currentIdx + 1) % numCells];
                    break;

                case 'ArrowLeft':
                    targetCell = cells[(currentIdx - 1 + numCells) % numCells];
                    break;

                case 'ArrowDown':
                    targetCell = cells[(currentIdx + numCols) % numCells];
                    break;

                case 'ArrowUp':
                    targetCell = cells[(currentIdx - numCols + numCells) % numCells];
                    break;

                default:
                    return;
            }

            if (targetCell) {
                event.preventDefault(); // Stop page from scrolling

                // Roving tabindex update
                active.setAttribute('tabindex', '-1');
                targetCell.setAttribute('tabindex', '0');
                targetCell.focus();
            }
        });

    }
}