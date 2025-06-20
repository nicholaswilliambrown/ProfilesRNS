// load via $.get(url) fails on some servers, status 301
// So using JS string instead of html file
// Perhaps try again with crossOriginAjax()

gCommon.mainDataContainer = $(`<div class="d-none container-fluid parentWidth p-0" id="main-data-container">
  <div class="row parentWidth">
    <div id="mainDiv" class="common">
      <div class="topOfPageItems">
        <nav id="topNavbar" class="top navbar navbar-expand-lg navbar-dark bg-dark">
          <div id="navbar1outerRow" class="row myNavbar-nav top mb-2 mb-lg-0 w-100">
            <div id="fourOrSoItems" class="row w-100">
              <div id="topNavHome" class="nav-item">
                <a id="topHome" class="nav-link top active" aria-current="page" href="#">
                  Home
                </a>
              </div>
              <div id="topNavAbout" class="nav-item dropdown">
                <a class="nav-link top dropdown-toggle" href="#" 
                    id="topNavAboutDropdown" role="button"
                   data-bs-toggle="dropdown" aria-expanded="false">
                  About
                </a>
                <ul id="topAboutDropdown" class="dropdown-menu bg-dark" aria-labelledby="topNavAboutDropdown">
                  <li><a id="overviewA" class="dropdown-item">Overview</a></li>
                  <li><p class="dropdown-divider p-0 m-0"/></li>
                  <li><a id="openSourceSoftwareA" class="dropdown-item">Open Source Software</a></li>
                  <li><p class="dropdown-divider p-0 m-0"/></li>                 
                </ul>
              </div>
              <div id="topNavHelp" class="nav-item">
                <a id="topNavHelpDropdown" class="nav-link top" aria-current="page">Help</a>
              </div>
              <div id="topNavHistory" class="nav-item dropdown">
                <a class="nav-link top dropdown-toggle" href="#" id="topNavHistoryDropdown" role="button"
                   data-bs-toggle="dropdown" aria-expanded="false">
                  History
                </a>
                <ul class="dropdown-menu" id="topHistoryDropdown" aria-labelledby="topNavHistoryDropdown">
                  <li><a id="seeAllPagesA" class="dropdown-item" href="#">See All Pages</a></li>
                </ul>
              </div>
              <div id="longerItem" class="nav-item d-flex flex-fill justify-content-end ">
                <div id="topNavSearch" class="nav-item ms-1 "></div>
              </div>
            </div>
          </div>
        </nav>
        <nav id="topNavbar2" class="top navbar2 me-1 navbar-expand-lg p-0 mb-2">
          <div id='topNavbarUser' class="myNavbar-nav2 navbar-nav d-flex flex-row me-auto mb-2 mb-lg-0">
          <div id="topNav2View" class="nav-item r2 nav-link2">
             <a id="viewMyProfileA" class="nav-link" aria-current="page" href="#">
                View My Profile
             </a>
            </div>
            <div id="topNav2Edit" class="nav-item r2 nav-link2">
             <a id="editMyProfileA" class="nav-link" aria-current="page" href="#">
                Edit My Profile
             </a>
            </div>
             <div id="topNav2EditThis" class="nav-item r2 nav-link2">
             <a id="editThisProfileA" class="nav-link" aria-current="page" href="#">
                Edit this Profile
             </a>
            </div>
            <div id="topNav2Proxies" class="nav-item r2 nav-link2">
             <a id="manageProxiesA" class="nav-link" aria-current="page" href="#">
              Manage Proxies
              </a>
            </div>
            <div id="topNav2Persons" class="nav-item r2 nav-link2 no-a-color dropdown">
              <a id="nav2Persons1" class="top dropdown-toggle no-a-color" href="#" role="button"
                 data-bs-toggle="dropdown" aria-expanded="false">
                My Person List (0)
                <ul id=topNav2PersonsDropdown class="dropdown-menu mt-2" aria-labelledby="nav2Persons1">
                  <li id="viewMyList"><a id="viewMyListA" class="dropdown-item r2" href="#">Visit my list and generate reports</a></li>
                  <li id="addMatchingPeopleList"><a id="addMatchingPeopleA" class="dropdown-item r2" href="#">Add matching people to my list</a></li>
                  <li id="removeMatchingPeopleList"><a id="removeMatchingPeopleA" class="dropdown-item r2" href="#">Remove matching people to my list</a></li>
                  <li id="clearPersonList"><a id="deleteAllFromListA" class="dropdown-item r2" href="#">Clear my list</a></li>
                  <li id="addPersonList"><a id="addPersonToListA" class="dropdown-item r2" href="#">Add this person to my list</a></li>
                  <li id="removePersonList"><a id="removePersonFromListA" class="dropdown-item r2" href="#">Remove person from list</a></li>
                </ul>
              </a>
            </div>
            <div id="topNav2Dashboard" class="nav-item r2 nav-link2">
             <a id="dashboardA" class="nav-link" aria-current="page" href="#">
              My Dashboard
              </a>
            </div>
            <div id="topNav2Opportunity" class="nav-item r2 nav-link2">
             <a id="opportunitySearchA" class="nav-link" aria-current="page" href="#">
              Opportunity Search
              </a>
            </div>
            <div id="topNav2Logout" class="nav-item r2 nav-link2">
              <a id="logoutA" class="nav-link" aria-current="page" href="#">
                Logout
              </a>
            </div>
            <div id="topNav2White" class="ms-auto"></div>

          </div>
        </nav>
        <div id="systemMessage" class="bold mt-2 mb-2 text-center"></div>
        <div id="inviteLoginDiv">
          <a id="loginA" class="link-ish" href="#">Login</a> to
          <span class="inviteLoginSpan">edit your profile</span>
          (add a photo, education, awards, etc.), search
          <span class="inviteLoginSpan">student opportunities</span>, and
          <span class="inviteLoginSpan">create reports</span>.
        </div>
      </div> <!-- top items -->

      <!-- page-specific items -->
      <div class="row modulesRow">
        <div id="modules-left-div">
        </div>
        <div id="modules-right-div">
        </div>
      </div>

      <div id="markPreFooter"></div>
    </div> <!-- mainDiv -->
  </div> <!-- row -->
</div> <!-- main-data-container -->
`);