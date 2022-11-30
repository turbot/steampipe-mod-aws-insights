dashboard "aws_codecommit_repository_detail" {

  title         = "AWS CodeCommit Repository Detail"
  documentation = file("./dashboards/codecommit/docs/codecommit_repository_detail.md")

  tags = merge(local.codecommit_common_tags, {
    type = "Detail"
  })

  input "codecommit_repository_arn" {
    title = "Select a repository:"
    query = query.aws_codecommit_repository_input
    width = 4
  }

  container {

    card {
      width = 2
      query = query.aws_codecommit_repository_default_branch
      args = {
        arn = self.input.codecommit_repository_arn.value
      }
    }

  }

  container {
    graph {
      title     = "Relationships"
      type      = "graph"
      direction = "TD"

      nodes = [
        node.aws_codecommit_repository_node,
        node.aws_codecommit_repository_to_codebuild_project_node,
        node.aws_codecommit_repository_to_codepipeline_pipeline_node
      ]

      edges = [
        edge.aws_codecommit_repository_to_codebuild_project_edge,
        edge.aws_codecommit_repository_to_codepipeline_pipeline_edge
      ]

      args = {
        arn = self.input.codecommit_repository_arn.value
      }
    }
  }

  container {

    width = 6

    table {
      title = "Overview"
      type  = "line"
      width = 6
      query = query.aws_codecommit_repository_overview
      args = {
        arn = self.input.codecommit_repository_arn.value
      }
    }

    table {
      title = "Tags"
      width = 6
      query = query.aws_codecommit_repository_tags
      args = {
        arn = self.input.codecommit_repository_arn.value
      }
    }
  }
}

query "aws_codecommit_repository_default_branch" {
  sql = <<-EOQ
    select
      'Default Branch' as "label",
      default_branch as "value"
    from
      aws_codecommit_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

query "aws_codecommit_repository_overview" {
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

  param "arn" {}
}

query "aws_codecommit_repository_tags" {
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

  param "arn" {}
}

query "aws_codecommit_repository_input" {
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

node "aws_codecommit_repository_node" {
  category = category.codecommit_repository

  sql = <<-EOQ
    select
      arn as id,
      title as title,
      jsonb_build_object(
        'Repository ID', repository_id,
        'Repository Name', repository_name,
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      aws_codecommit_repository
    where
      arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codecommit_repository_to_codebuild_project_node" {
  category = category.codebuild_project

  sql = <<-EOQ
    select
      p.arn as id,
      p.title as title,
      jsonb_build_object(
        'Name', p.name,
        'ARN', p.arn,
        'Account ID', p.account_id,
        'Region', p.region
      ) as properties
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
      r.arn = $1;
  EOQ

  param "arn" {}
}

edge "aws_codecommit_repository_to_codebuild_project_edge" {
  title = "codebuild project"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_codecommit_repository r
      left join aws_codebuild_project p on r.clone_url_http in (
        select
          source ->> 'Location' as "l"
        from aws_codebuild_project
        union all
        select
          s ->> 'Location' as "l"
        from aws_codebuild_project,
          jsonb_array_elements(aws_codebuild_project.secondary_sources) as s
      )
    where
      r.arn = $1;
  EOQ

  param "arn" {}
}

node "aws_codecommit_repository_to_codepipeline_pipeline_node" {
  category = category.codepipeline_pipeline

  sql = <<-EOQ
    select
      p.arn as id,
      p.title as title,
      jsonb_build_object(
        'ARN', p.arn,
        'Account ID', p.account_id,
        'Region', p.region
      ) as properties
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

  param "arn" {}
}

edge "aws_codecommit_repository_to_codepipeline_pipeline_edge" {
  title = "codepipeline pipeline"

  sql = <<-EOQ
    select
      r.arn as from_id,
      p.arn as to_id
    from
      aws_codecommit_repository as r
      cross join aws_codepipeline_pipeline as p
    where
      r.arn = $1 and p.stages is not null
      and r.repository_name in (
      select jsonb_path_query(p.stages, '$[*].Actions[*].Configuration.RepositoryName')::text
    );
  EOQ

  param "arn" {}
}
