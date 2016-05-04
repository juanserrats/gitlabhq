module Gitlab
  module ImportExport
    class ImportService

      def self.execute(*args)
        new(*args).execute
      end

      def initialize(archive_file:, owner:, namespace_id:, project_path:)
        @archive_file = archive_file
        @current_user = owner
        @namespace = Namespace.find(namespace_id)
        @project_path = project_path
      end

      def execute
        Gitlab::ImportExport::Importer.import(archive_file: @archive_file, storage_path: storage_path)
        project_tree.project if [restore_project_tree, restore_repo].all?
      end

      private

      def restore_project_tree
        project_tree.restore
      end

      def project_tree
        @project_tree ||= Gitlab::ImportExport::ProjectTreeRestorer.new(path: storage_path, user: @current_user, project_path: @project_path, namespace_id: @namespace.id)
      end

      def restore_repo
        Gitlab::ImportExport::RepoRestorer.new(path: storage_path, project: project_tree.project).restore
      end

      def storage_path
        @storage_path ||= Gitlab::ImportExport.export_path(relative_path: path_with_namespace)
      end

      def path_with_namespace
        File.join(@namespace.path, @project_path)
      end
    end
  end
end
