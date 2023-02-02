dashboard "codecommit_repository_detail" {

  title         = "AWS CodeCommit Repository Detail"
  documentation = file("./dashboards/codecommit/docs/codecommit_repository_detail.md")

  tags = merge(local.codecommit_common_tags, {
    type = "Detail"
  })

  input "codecommit_repository_arn" {
    title = "Select a repository:"
    query = query.codecommit_repository_input
    width = 4
  }

  container {

    card {
      width = 3
      query = query.codecommit_repository_default_branch
      args  = [self.input.codecommit_repository_arn.value]
    }
  }

  with "codebuild_projects_for_codecommit_repository" {
    query = query.codebuild_projects_for_codecommit_repository
    args  = [self.input.codecommit_repository_arn.value]
  }

  with "codepipeline_pipelines_for_codecommit_repository" {
    query = query.codepipeline_pipelines_for_codecommit_repository
    args  = [self.input.codecommit_repository_arn.value]
  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      node {
        base = node.codebuild_project
        args = {
          codebuild_project_arns = with.codebuild_projects_for_codecommit_repository.rows[*].codebuild_project_arn
        }
      }

      node {
        base = node.codecommit_repository
        args = {
          codecommit_repository_arns = [self.input.codecommit_repository_arn.value]
        }
      }

      node {
        base = node.codepipeline_pipeline
        args = {
          codepipeline_pipeline_arns = with.codepipeline_pipelines_for_codecommit_repository.rows[*].codepipeline_pipeline_arn
        }
      }

      edge {
        base = edge.codecommit_repository_to_codebuild_project
        args = {
          codecommit_repository_arns = [self.input.codecommit_repository_arn.value]
        }
      }

      edge {
        base = edge.codecommit_repository_to_codepipeline_pipeline
        args = {
          codecommit_repository_arns = [self.input.codecommit_repository_arn.value]
        }
      }
    }
  }

  container {

    width = 6

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.codecommit_repository_overview
      args  = [self.input.codecommit_repository_arn.value]
    }

    table {
      title = "Tags"
      width = 6
      query = query.codecommit_repository_tags
      args  = [self.input.codecommit_repository_arn.value]
    }
  }
}

# Input queries

query "codecommit_repository_input" {
  sql = <<-EOQ
    select
      title as label,
      arn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'arn', arn
      ) as tags
    from
      aws_codecommit_repository
    order by
      title;
  EOQ
}

# With queries

query "codebuild_projects_for_codecommit_repository" {
  sql = <<-EOQ
    select
      p.arn as codebuild_project_arn
    from
      aws_codecommit_repository as r
      left join aws_codebuild_project as p on r.clone_url_http in (
        select
          source ->> 'Location' as "l"
        from
          aws_codebuild_project
        union all
        select
          s ->> 'Location' as "l"
        from
          aws_codebuild_project,
          jsonb_array_elements(aws_codebuild_project.secondary_sources) as s
      )
    where
      p.arn is not null
      and r.arn = $1;
  EOQ
}

query "codepipeline_pipelines_for_codecommit_repository" {
  sql = <<-EOQ
    select
      p.arn as codepipeline_pipeline_arn
    from
      aws_codecommit_repository r
      cross join aws_codepipeline_pipeline as p
    where
      r.arn = $1 and p.stages is not null
      and r.repository_name in (
        select
          jsonb_path_query(p.stages, '$[*].Actions[*].Configuration.RepositoryName')::text
      );
  EOQ
}

# Card queries

query "codecommit_repository_default_branch" {
  sql = <<-EOQ
    select
      'Default Branch' as "label",
      default_branch as "value"
    from
      aws_codecommit_repository
    where
      arn = $1;
  EOQ
}

# Other detail page queries

query "codecommit_repository_overview" {
  sql = <<-EOQ
    select
      repository_name as "Repository Name",
      repository_id as "Repository ID",
      description as "Description",
      arn as "ARN",
      clone_url_http as "HTTP Clone URL",
      clone_url_ssh as "SSH Clone URL",
      creation_date as "Creation date",
      last_modified_date as "Last modified date"
    from
      aws_codecommit_repository
    where
      arn = $1;
  EOQ
}

query "codecommit_repository_tags" {
  sql = <<-EOQ
    select
      tag.Key as "Key",
      tag.Value as "Value"
    from
      aws_codecommit_repository,
      jsonb_each_text(tags) as tag
    where
      arn = $1
    order by
      tag.Key;
  EOQ
}


