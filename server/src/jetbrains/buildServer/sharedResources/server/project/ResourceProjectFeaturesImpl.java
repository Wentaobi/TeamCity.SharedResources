/*
 * Copyright 2000-2016 JetBrains s.r.o.
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

package jetbrains.buildServer.sharedResources.server.project;

import jetbrains.buildServer.serverSide.SProject;
import jetbrains.buildServer.serverSide.SProjectFeatureDescriptor;
import jetbrains.buildServer.sharedResources.SharedResourcesPluginConstants;
import jetbrains.buildServer.sharedResources.model.resources.Resource;
import jetbrains.buildServer.sharedResources.model.resources.ResourceFactory;
import jetbrains.buildServer.sharedResources.server.exceptions.DuplicateResourceException;
import jetbrains.buildServer.util.CollectionsUtil;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Created with IntelliJ IDEA.
 *
 * @author Oleg Rybak (oleg.rybak@jetbrains.com)
 */
public class ResourceProjectFeaturesImpl implements ResourceProjectFeatures {

  @Override
  public void addResource(@NotNull SProject project, @NotNull Map<String, String> resourceParameters) throws DuplicateResourceException {
    final String name = resourceParameters.get("name");
    if (getResourceNamesInProject(project).contains(name)) {
      throw new DuplicateResourceException(name);
    }
    project.addFeature(SharedResourcesPluginConstants.SERVICE_NAME, resourceParameters);
  }

  @Override
  public void deleteResource(@NotNull final SProject project, @NotNull final String name) {
    final SProjectFeatureDescriptor descriptor = findDescriptorByResourceName(project, name);
    if (descriptor != null) {
      project.removeFeature(descriptor.getId());
    }
  }

  @Override
  public void editResource(@NotNull final SProject project, @NotNull final String name, @NotNull final Map<String, String> resourceParameters) throws DuplicateResourceException {
    final SProjectFeatureDescriptor descriptor = findDescriptorByResourceName(project, name);
    if (descriptor != null) {
      final String newName = resourceParameters.get("name");
      if (!name.equals(newName)) {
        if (getResourceNamesInProject(project).contains(newName)) {
          throw new DuplicateResourceException(newName);
        }
      }
      project.updateFeature(descriptor.getId(), SharedResourcesPluginConstants.SERVICE_NAME, resourceParameters);
    }
  }


  @Nullable
  private SProjectFeatureDescriptor findDescriptorByResourceName(@NotNull final SProject project,
                                                                 @NotNull final String name) {
    final Optional<SProjectFeatureDescriptor> descriptor = project.getFeaturesOfType(SharedResourcesPluginConstants.SERVICE_NAME)
            .stream()
            .filter(fd -> name.equals(fd.getParameters().get("name")))
            .findFirst();
    if (descriptor.isPresent()) {
      return descriptor.get();
    }
    return null;
  }

  @NotNull
  @Override
  public Map<SProject, Map<String, Resource>> asProjectResourceMap(@NotNull final SProject project) {
    final Map<SProject, Map<String, Resource>> result = new LinkedHashMap<>();
    // we need only names here
    final Map<String, Resource> treeResources = new HashMap<>();

    final List<SProject> path = project.getProjectPath();
    final ListIterator<SProject> it = path.listIterator(path.size());
    while (it.hasPrevious()) {
      SProject p = it.previous();
      Map<String, Resource> currentResources = getResourcesForProject(p);
      final Map<String, Resource> value = CollectionsUtil.filterMapByKeys(
              currentResources, data -> !treeResources.containsKey(data)
      );
      treeResources.putAll(value);
      result.put(p, value);
    }
    return result;
  }

  @Override
  public Map<String, Resource> asMap(@NotNull SProject project) {
    final Map<String, Resource> result = new TreeMap<>(SharedResourcesPluginConstants.RESOURCE_NAMES_COMPARATOR);
    final List<SProject> path = project.getProjectPath();
    final ListIterator<SProject> it = path.listIterator(path.size());
    while (it.hasPrevious()) {
      SProject p = it.previous();
      Map<String, Resource> currentResources = getResourcesForProject(p);
      result.putAll(CollectionsUtil.filterMapByKeys(currentResources, data -> !result.containsKey(data)));
    }
    return result;
  }

  private Set<String> getResourceNamesInProject(@NotNull final SProject project) {
    return project.getFeaturesOfType(SharedResourcesPluginConstants.SERVICE_NAME)
            .stream()
            .map(fd -> fd.getParameters().get("name"))
            .collect(Collectors.toSet());
  }

  @NotNull
  private Map<String, Resource> getResourcesForProject(@NotNull final SProject project) {
    final Map<String, Resource> result = new TreeMap<>(new Comparator<String>() {
      @Override
      public int compare(String o1, String o2) {
        return o1.compareToIgnoreCase(o2);
      }
    });
    result.putAll(project.getFeaturesOfType(SharedResourcesPluginConstants.SERVICE_NAME)
            .stream()
            .collect(Collectors.toMap(rd -> rd.getParameters().get("name"), rd -> ResourceFactory.getFactory(project.getProjectId()).createResource(rd.getParameters()))));
    return result;
  }
}
