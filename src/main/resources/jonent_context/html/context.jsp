<%@ taglib prefix="jcr" uri="http://www.jahia.org/tags/jcr" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="utility" uri="http://www.jahia.org/tags/utilityLib" %>
<%@ taglib prefix="template" uri="http://www.jahia.org/tags/templateLib" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%--@elvariable id="currentNode" type="org.jahia.services.content.JCRNodeWrapper"--%>
<%--@elvariable id="out" type="java.io.PrintWriter"--%>
<%--@elvariable id="script" type="org.jahia.services.render.scripting.Script"--%>
<%--@elvariable id="scriptInfo" type="java.lang.String"--%>
<%--@elvariable id="workspace" type="java.lang.String"--%>
<%--@elvariable id="renderContext" type="org.jahia.services.render.RenderContext"--%>
<%--@elvariable id="currentResource" type="org.jahia.services.render.Resource"--%>
<%--@elvariable id="url" type="org.jahia.services.render.URLGenerator"--%>
<%--@elvariable id="portalContext" type="org.jahia.modules.portal.service.bean.PortalContext"--%>

<template:addResources type="javascript" resources="angular.min.js"/>
<template:addResources type="javascript" resources="underscore.js"/>

<jcr:node var="rootNode" path="/sites/${portalContext.siteKey}/contents/messages"/>
<c:set var="rootNodeId" value="${rootNode.identifier}"/>

<c:if test="${renderContext.editMode}">
    This is a component that init context for messages app demo<br>
    injecting angularjs services related to messages.
</c:if>

<script type="text/javascript">
    angular.module('messagesServiceApp', [])
            .service('messageServices', function () {
                this.generateId = function () {
                    return '_' + Math.random().toString(36).substr(2, 9);
                };

                this.getChannels = function (cb) {
                    var instance = this;
                    JCRRestUtils.standardCall(JCRRestUtils.buildURL("", "", "nodes", "${rootNodeId}/children"), "GET", null, function (data) {
                        instance.channels = data.children;
                        if (cb) {
                            cb(data)
                        }
                    });
                };

                this.getChannel = function (channelName, cb) {
                    JCRRestUtils.standardCall(JCRRestUtils.buildURL("", "", "paths", "sites/${portalContext.siteKey}/contents/messages/" + channelName), "GET", null, function (data) {
                        if (cb) {
                            cb(data)
                        }
                    });
                };

                this.createChannel = function (channelName, cb) {
                    var instance = this;
                    var url = JCRRestUtils.buildURL("", "", "", "${rootNodeId}");
                    var data = JCRRestUtils.createUpdateChildData(channelName, "jonent:channel");

                    JCRRestUtils.standardCall(url, "PUT",
                            JSON.stringify(data),
                            function (respons) {
                                instance.channels[channelName] = {};
                                if (cb) {
                                    cb(respons);
                                }
                            });
                };

                this.postMessage = function (channelName, message, cb) {
                    var instance = this;
                    this.getChannel(channelName, function (channelData) {
                        var url = JCRRestUtils.buildURL("", "", "nodes", channelData.id);
                        var data = JCRRestUtils.createUpdateChildData(instance.generateId(), "jonent:message",
                                {
                                    "body": {"value": message},
                                    "author": {"value": "${renderContext.user.username}"},
                                    "created": {"value": new Date().toString()}
                                });

                        JCRRestUtils.standardCall(url, "PUT",
                                JSON.stringify(data),
                                function (respons) {
                                    if (cb) {
                                        cb(respons);
                                    }
                                });
                    })
                };

                this.getMessages = function (channel, cb) {
                    JCRRestUtils.standardCall(JCRRestUtils.buildURL("", "", "paths", "sites/${portalContext.siteKey}/contents/messages/" + channel + "/children?includeFullChildren"), "GET", null, function (data) {
                        if (cb) {
                            cb(_.sortBy(data.children, function(o) { return o.properties.created.value; }))
                        }
                    });
                };

                this.updateWidget = function (widget) {
                    var instance = this;
                    var serializedForm = $("#" + widget._id + " form").serializeArray();
                    var indexedForm = _.indexBy(serializedForm, 'name')["room"];
                    if(indexedForm) {
                        var channel = indexedForm.value;
                        if (channel) {
                            if(instance.channels[channel]){
                                widget.performUpdate(serializedForm, function (data) {
                                    widget.load();
                                });
                            } else {
                                instance.createChannel(channel, function(){
                                    widget.performUpdate(serializedForm, function (data) {
                                        widget.load();
                                    });
                                })
                            }
                        }
                    }
                };

                // init
                this.getChannels();
            })

            .directive('widgetInjector', [function () {
                return {
                    restrict: "A",
                    scope: {
                        widgetData: '=widgetInjector',
                        widget: '=widget',
                        room: '=room'
                    },
                    controller: function ($scope) {
                        $scope.widget = portal.getCurrentWidget($scope.widgetData.widgetId);
                        $scope.room = $scope.widgetData.room;
                    }
                }
            }]);
</script>