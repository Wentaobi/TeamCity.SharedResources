/*
 * Copyright 2000-2013 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package jetbrains.buildServer.sharedResources.server.feature;

import jetbrains.buildServer.serverSide.ProjectManager;
import jetbrains.buildServer.serverSide.SProject;
import jetbrains.buildServer.serverSide.settings.ProjectSettingsManager;
import jetbrains.buildServer.sharedResources.model.resources.Resource;
import jetbrains.buildServer.sharedResources.server.exceptions.DuplicateResourceException;
import jetbrains.buildServer.sharedResources.server.project.ResourceProjectFeatures;
import org.jetbrains.annotations.NotNull;

import java.util.Map;

/**
 * Created with IntelliJ IDEA.
 *
 * @author Oleg Rybak (oleg.rybak@jetbrains.com)
 */
public final class ResourcesImpl implements Resources {

  @NotNull
  private final ResourceProjectFeatures myFeatures;

  @NotNull
  private final ProjectSettingsManager myProjectSettingsManager;

  @NotNull
  private final ProjectManager myProjectManager;


  public ResourcesImpl(@NotNull final ProjectSettingsManager projectSettingsManager,
                       @NotNull final ProjectManager projectManager,
                       @NotNull final ResourceProjectFeatures resourceProjectFeatures) {
    myProjectSettingsManager = projectSettingsManager;
    myProjectManager = projectManager;
    myFeatures = resourceProjectFeatures;
  }

  @Override
  @Deprecated
  public void addResource(@NotNull final Resource resource) throws DuplicateResourceException {

  }

  @Override
  public void addResource(@NotNull final SProject project, @NotNull final Resource resource) throws DuplicateResourceException {
    myFeatures.addResource(project, resource.getParameters());
  }

  @Override
  @Deprecated
  public void deleteResource(@NotNull final String projectId, @NotNull final String resourceName) {

  }

  @Override
  public void deleteResource(@NotNull final SProject project, @NotNull final String resourceName) {
    myFeatures.deleteResource(project, resourceName);
  }

  @Override
  @Deprecated
  public void editResource(@NotNull final String projectId,
                           @NotNull final String currentName,
                           @NotNull final Resource newResource) throws DuplicateResourceException {
  }

  @Override
  public void editResource(@NotNull final SProject project,
                           @NotNull final String currentName,
                           @NotNull final Resource resource) throws DuplicateResourceException {
    myFeatures.editResource(project, currentName, resource.getParameters());
  }

  @NotNull
  @Override
  public Map<String, Resource> asMap(@NotNull final String projectId) {
    return myFeatures.asMap(myProjectManager.findProjectById(projectId)); //todo: projectId -> project
  }

  @NotNull
  @Override
  public Map<SProject, Map<String, Resource>> asProjectResourceMap(@NotNull String projectId) {
    return myFeatures.asProjectResourceMap(myProjectManager.findProjectById(projectId)); //todo: projectId -> project
  }

  @Override
  public int getCount(@NotNull final String projectId) {
    return myFeatures.asMap(myProjectManager.findProjectById(projectId)).size();
  }


}
