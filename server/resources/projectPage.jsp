<%--
  ~ Copyright 2000-2013 JetBrains s.r.o.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  --%>
<%@ include file="/include-internal.jsp" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants" %>
<%@ page import="jetbrains.buildServer.sharedResources.model.resources.ResourceType" %>

<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="bean" scope="request" type="jetbrains.buildServer.sharedResources.pages.SharedResourcesBean"/>

<c:set var="PARAM_RESOURCE_NAME" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_NAME%>"/>
<c:set var="PARAM_PROJECT_ID" value="<%=SharedResourcesPluginConstants.WEB.PARAM_PROJECT_ID%>"/>
<c:set var="PARAM_RESOURCE_QUOTA" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_QUOTA%>"/>
<c:set var="PARAM_RESOURCE_TYPE" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_TYPE%>"/>
<c:set var="PARAM_RESOURCE_VALUES" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_VALUES%>"/>
<c:set var="PARAM_OLD_RESOURCE_NAME" value="<%=SharedResourcesPluginConstants.WEB.PARAM_OLD_RESOURCE_NAME%>"/>
<c:set var="PARAM_RESOURCE_STATE" value="<%=SharedResourcesPluginConstants.WEB.PARAM_RESOURCE_STATE%>"/>

<c:set var="ACTIONS" value="<%=SharedResourcesPluginConstants.WEB.ACTIONS%>"/>

<c:set var="type_quota" value="<%=ResourceType.QUOTED%>"/>
<c:set var="type_custom" value="<%=ResourceType.CUSTOM%>"/>


<c:url var="url" value="editProject.html?projectId=${project.projectId}&tab=JetBrains.SharedResources"/>

<script type="text/javascript">

  BS.SharedResourcesActions = {
    getCommonParams: function () {
      // if quota checkbox in unchecked, send no quota info
      var type = $j('#resource_type option:selected').val();
      var params = {};
      params['${PARAM_PROJECT_ID}'] = '${project.projectId}';
      params['${PARAM_RESOURCE_NAME}'] = $j('#resource_name').val();
      params['${PARAM_RESOURCE_STATE}'] = $j('#resource_enabled').prop('checked');

      // infinite
      if (type === 'infinite') {
        params['${PARAM_RESOURCE_TYPE}'] = 'quoted';
      }
      // quoted
      if (type === 'quoted') {
        params['${PARAM_RESOURCE_TYPE}'] = 'quoted';
        params['${PARAM_RESOURCE_QUOTA}'] = $j('#resource_quota').val();
      }
      // custom
      if (type === 'custom') {
        params['${PARAM_RESOURCE_TYPE}'] = 'custom';
        params['${PARAM_RESOURCE_VALUES}'] = $j('#customValues').val();
      }
      return params;
    },

    actionsUrl: window['base_uri'] + "${ACTIONS}",
    addResource: function () {
      var params = this.getCommonParams();
      params['action'] = 'addResource';
      BS.ajaxRequest(this.actionsUrl, {
        parameters: params,
        onComplete: function (transport) {
          var errors = BS.XMLResponse.processErrors(transport.responseXML, {
            onNameError: function (elem) {
              $j('#error_Name').html("The name is already used");
              BS.Util.show('error_Name');
            }
          });

          if (!errors) {
            window.location.reload();
          }
        }
      });
      return false;
    },

    editResource: function (old_resource_name) {
      var params = this.getCommonParams();
      params['${PARAM_OLD_RESOURCE_NAME}'] = old_resource_name;
      params['action'] = 'editResource';
      BS.ajaxRequest(this.actionsUrl, {
        parameters: params,
        onComplete: function (transport) {
          var errors = BS.XMLResponse.processErrors(transport.responseXML, {
            onNameError: function (elem) {
              $j('#error_Name').html("Name is already used");
              BS.Util.show('error_Name');
            }
          });

          if (!errors) {
            window.location.reload();
          }
        }
      });
      return false;
    },

    deleteResource: function (resource_name) {
      var params = {};
      params['${PARAM_PROJECT_ID}'] = '${project.projectId}';
      params['${PARAM_RESOURCE_NAME}'] = resource_name;
      params['action'] = 'deleteResource';

      if (confirm('Are you sure you want to delete this resource?')) {
        BS.ajaxRequest(this.actionsUrl, {
          parameters: params,
          onSuccess: function () {
            window.location.reload();
          }
        });
      }
    },

    alertCantDelete: function (resource_name) {
      alert('Resource ' + resource_name + " can't be deleted because it is in use");
    },

    enableDisableResource: function (resource_name, new_state) {
      var params = {};
      params['${PARAM_PROJECT_ID}'] = '${project.projectId}';
      params['${PARAM_RESOURCE_NAME}'] = resource_name;
      params['${PARAM_RESOURCE_STATE}'] = new_state;
      params['action'] = 'enableDisableResource';
      if (confirm('Are you sure you want to ' + (new_state ? 'enable' : 'disable') + ' this resource?')) {
        BS.ajaxRequest(this.actionsUrl, {
          parameters: params,
          onSuccess: function () {
            window.location.reload();
          }
        });
      }
    }
  };


</script>


<script type="text/javascript">
  var myValues;
  var r;
  var v;
  <c:forEach var="item" items="${bean.allResources}">
  <c:set var="type" value="${item.type}"/>
  r = {
    name: '<bs:escapeForJs text="${item.name}"/>',
    type: '${item.type}',
    enabled: ${item.enabled}
  };
  <c:choose>

  <%-- quoted resource--%>
  <c:when test="${type == type_quota}">
  r['quota'] = '${item.quota}';
  r['infinite'] = ${item.infinite};
  BS.ResourceDialog.myData['<bs:escapeForJs text="${item.name}"/>'] = r;
  </c:when>

  <%-- custom resource--%>
  <c:when test="${type == type_custom}">
  myValues = [];
  <c:forEach items="${item.values}" var="val">
  myValues.push('<bs:escapeForJs text="${val}"/>');
  </c:forEach>
  r['customValues'] = myValues;
  BS.ResourceDialog.myData['<bs:escapeForJs text="${item.name}"/>'] = r;
  </c:when>

  <c:otherwise>
  console.log('Resource [<bs:escapeForJs text="${item.name}"/>] was not recognized');
  </c:otherwise>
  </c:choose>
  BS.ResourceDialog.existingResources['<bs:escapeForJs text="${item.name}"/>'] = true;
  </c:forEach>
</script>

<div>
  This page contains shared resources defined in the current project, as well as inherited resources.<bs:help file="Shared+Resources"/>
</div>

<div>
<p>
  <forms:addButton id="addNewResource"
                   onclick="BS.ResourceDialog.showDialog(); return false">Add new resource</forms:addButton>
</p>
<bs:dialog dialogId="resourceDialog" titleId="resourceDialogTitle"
           title="Resource Management" closeCommand="BS.ResourceDialog.close()">
  <table class="runnerFormTable">
    <tr>
      <th style="white-space: nowrap"><label for="resource_name">Resource name: <l:star/></label></th>
      <td>
        <forms:textField name="resource_name" id="resource_name" style="width: 90%"
                         className="longField buildTypeParams" maxlength="40"/>
        <span class="error" id="error_Name"></span>
        <span id="nameAttention" class="smallNoteAttention" style="display: none">
            <bs:out value="Please check whether the resource name is used as a "/>
            <bs:helpLink file="Defining+and+Using+Build+Parameters+in+Build+Configuration">
              <bs:out value="parameter reference."/>
            </bs:helpLink>
            <bs:out value="Changing the name can result in unsatisfied "/>
            <bs:helpLink file="Agent+Requirements">
              <bs:out value="agent requirement"/>
            </bs:helpLink>
        </span>
      </td>
    </tr>
    <tr>
      <th style="white-space: nowrap">Resource type:<bs:help file="Shared+Resources"/></th>
      <td>
        <forms:select name="resoruce_type" id="resource_type" style="width: 90%"
                      onchange="BS.ResourceDialog.syncResourceSelectionState(); return true;">
          <forms:option value="infinite">Infinite resource</forms:option>
          <forms:option value="quoted">Resource with quota</forms:option>
          <forms:option value="custom">Resource with custom values</forms:option>
        </forms:select>
      </td>
    </tr>
    <tr>
      <th style="white-space: nowrap">Enabled: </th>
      <td>
        <forms:checkbox name="resource_enabled" id="resource_enabled" checked="true"/>
      </td>
    </tr>
    <tr id="quota_row" style="display: none">
      <th style="white-space: nowrap"><label for="resource_quota">Resource quota: <l:star/></label></th>
      <td>
        <forms:textField name="resource_quota" style="width: 15%" id="resource_quota"
                         className="longField buildTypeParams" maxlength="3"/>
        <span class="error" id="error_Quota"></span>
        <span class="smallNote">Quota is a number of concurrent read locks that can be acquired on the resource</span>
      </td>
    </tr>
    <tr id="custom_row" style="display: none">
      <th style="white-space: nowrap">Custom values: <l:star/></th>
      <td>
        <props:textarea name="customValues" textAreaName="customValuesArea" value=""
                        linkTitle="Define custom values" cols="30" rows="5" expanded="${true}"/>
        <span class="error" id="error_Values"></span>
        <span class="smallNote">Define one custom value for the resource per line</span>
      </td>
    </tr>
  </table>
  <div class="popupSaveButtonsBlock">
    <forms:cancel onclick="BS.ResourceDialog.close()" showdiscardchangesmessage="false"/>
    <forms:submit id="resourceDialogSubmit" type="button" label="Save" onclick="BS.ResourceDialog.submit()"/>
  </div>
</bs:dialog>


<c:choose>
  <c:when test="${not empty bean.myResources}">
    <h3>Resources defined in the current project</h3>
    <l:tableWithHighlighting style="width: 70%"
                             id="resourcesTable"
                             className="parametersTable"
                             mouseovertitle="Click to edit resource"
                             highlightImmediately="true">
      <tr>
        <th>Resource name</th>
        <th style="width:55%" colspan="4">Resource description</th>
      </tr>
      <%@ include file="_displayResources.jspf" %>
    </l:tableWithHighlighting>
  </c:when>
  <c:otherwise>
    <p>
      <c:out value="There are no resources defined in the current project."/>
    </p>
  </c:otherwise>
</c:choose>


<c:forEach var="item" items="${bean.inheritedResources}">
  <c:set var="p" value="${item.key}"/> <%-- project --%>
  <c:set var="pr" value="${item.value}"/> <%--Map<String, Resource>--%>
  <c:if test="${not empty pr}">
    <h3>Resources inherited from
      <authz:authorize projectId="${p.externalId}" allPermissions="EDIT_PROJECT" >
      <jsp:attribute name="ifAccessGranted">
        <c:url var="editUrl" value="/admin/editProject.html?projectId=${p.externalId}&tab=JetBrains.SharedResources"/>
        <a href="${editUrl}"><c:out value="${p.extendedFullName}"/></a>
      </jsp:attribute>
      <jsp:attribute name="ifAccessDenied">
        <bs:projectLink project="${p}"><c:out value="${p.extendedFullName}"/></bs:projectLink>
      </jsp:attribute>
      </authz:authorize>
    </h3>
    <table class="parametersTable" style="width: 70%">
      <tr>
        <th>Resource name</th>
        <th style="width:55%" colspan="2">Resource description</th>
      </tr>
      <c:forEach var="resource" items="${pr}">
        <c:set var="usage" value="${bean.usageMap[resource.key]}"/> <%--Map<SBuildType -> LockType>--%>
        <c:set var="used" value="${not empty usage}"/>

        <tr>
          <td><bs:out value="${resource.key}"/></td>
          <c:choose>
            <c:when test="${resource.value.type == type_quota}">
              <c:choose>
                <c:when test="${resource.value.infinite}">
                  <td>Quota: Infinite</td>
                </c:when>
                <c:otherwise>
                  <td>Quota: <c:out value="${resource.value.quota}"/></td>
                </c:otherwise>
              </c:choose>
            </c:when>
            <c:when test="${resource.value.type == type_custom}">
              <td>Custom values</td>
            </c:when>
          </c:choose>

          <c:choose>
            <c:when test="${used}">
              <td>
                <%@ include file="_resourceUsage.jspf" %>
              </td>
            </c:when>
            <c:otherwise>
              <td>Resource is not used</td>
            </c:otherwise>
          </c:choose>
        </tr>
      </c:forEach>
    </table>
  </c:if>
</c:forEach>
</div>

