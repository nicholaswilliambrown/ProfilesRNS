// load via $.get(url) fails on some servers, status 301
// So using JS string instead of html file
// Perhaps try again with crossOriginAjax()

gCommon.mainDataContainer = $(`<div class="container-fluid parentWidth p-0 mb-4" id="main-data-container">
  <div class="row parentWidth">
    <div id="mainDiv" class="common">
      <div class="topOfPageItems">
        <nav id="topNavbar" class="top navbar navbar-expand-lg navbar-dark bg-dark">
          <div id="navbar1outerRow" class="row myNavbar-nav top me-auto mb-2 mb-lg-0 w-100">
            <div id="fourItems" class="row">
              <div id="topNavHome" class="nav-item">
                <a id="topHome" class="nav-link top active" aria-current="page" href="#">
                  Home
                </a>
              </div>
              <div id="topNavAbout" class="nav-item dropdown">
                <a class="nav-link top dropdown-toggle" href="#" 
                    id="navbarDropdown1" role="button"
                   data-bs-toggle="dropdown" aria-expanded="false">
                  About
                </a>
                <ul class="dropdown-menu bg-dark" aria-labelledby="navbarDropdown1">
                  <li><a id="overviewA" class="dropdown-item">Overview</a></li>
                  <li><p class="dropdown-divider p-0 m-0"/></li>
                  <li><a id="openSourceSoftwareA" class="dropdown-item">Open Source Software</a></li>
                </ul>
              </div>
              <div id="topNavHelp" class="nav-item">
                <a id="helpA" class="nav-link top" aria-current="page">Help</a>
              </div>
              <div id="topNavHistory" class="nav-item dropdown">
                <a class="nav-link top dropdown-toggle" href="#" id="navbarDropdown2" role="button"
                   data-bs-toggle="dropdown" aria-expanded="false">
                  History
                </a>
                <ul class="dropdown-menu" id="topHistoryDropdown" aria-labelledby="navbarDropdown2">
                  <li><p class="dropdown-divider"/></li>
                  <li><a id="seeAllPagesA" class="dropdown-item" href="#">See All Pages</a></li>
                </ul>
              </div>
            </div>
            <div id="longerItem" class="row">
              <div id="topNavSearch" class="nav-item ms-1"></div>
            </div>
          </div>
        </nav>
        <nav id="topNavbar2" class="top navbar2 navbar-expand-lg p-0 mb-2">
          <div class="myNavbar-nav me-auto mb-2 mb-lg-0">
            <div id="topNav2Edit" class="nav-item r2 nav-link2">
              Edit My Profile
            </div>
            <div id="topNav2Proxies" class="nav-item r2 nav-link2">
              Manage Proxies
            </div>
            <div id="topNav2Persons" class="nav-item r2 nav-link2 no-a-color dropdown">
              <a id="nav2Persons" class="top dropdown-toggle no-a-color" href="#" role="button"
                 data-bs-toggle="dropdown" aria-expanded="false">
                My Person List (0)
                <ul class="dropdown-menu mt-2" aria-labelledby="nav2Persons">
                  <li><a class="dropdown-item r2" href="#">Visit my list and generate reports</a></li>
                  <li id="clearPersonList"><a class="dropdown-item r2" href="#">Clear my list</a></li>
                  <li id="addPersonList"><a class="dropdown-item r2" href="#">Add this person to my list</a></li>
                  <li id="removePersonList"><a class="dropdown-item r2" href="#">Remove person from list</a></li>
                </ul>
              </a>
            </div>
            <div id="topNav2Opportunity" class="nav-item r2 nav-link2">
              Opportunity Search
            </div>
            <div id="topNav2Logout" class="nav-item r2 nav-link2">
              <a id="logoutA" class=" no-a-color" aria-current="page" href="#">
                Logout
              </a>
            </div>
            <div id="topNav2White" class="ms-auto"></div>

          </div>
        </nav>
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