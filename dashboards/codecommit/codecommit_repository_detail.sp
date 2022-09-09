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
      type  = "graph"
      base  = graph.aws_graph_categories
      title = "Relationships"
      query = query.aws_codecommit_repository_relationships_graph
      args = {
        arn = self.input.codecommit_repository_arn.value
      }

      category "aws_codebuild_project" {}
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

query "aws_codecommit_repository_relationships_graph" {
  sql = <<-EOQ
    with repository as (
      select
        *
      from
        aws_codecommit_repository
      where
        arn = $1
    )

    -- Resource (node)
    select
      null as from_id,
      null as to_id,
      arn as id,
      title as title,
      'aws_codecommit_repository' as category,
      jsonb_build_object(
        'ARN', arn,
        'Account ID', account_id,
        'Region', region
      ) as properties
    from
      repository

    -- To CodeBuild Project (node)
    union all
    select
      null as from_id,
      null as to_id,
      cbproject.arn as id,
      cbproject.title as title,
      'aws_codebuild_project' as category,
      jsonb_build_object(
        'ARN', cbproject.arn,
        'Account ID', cbproject.account_id,
        'Region', cbproject.region
      ) as properties
    from
      repository
    left join aws_codebuild_project cbproject
      on repository.clone_url_http in (
        select source ->> 'Location' as "l" from aws_codebuild_project
        union all
        select s ->> 'Location' as "l" from aws_codebuild_project, jsonb_array_elements(aws_codebuild_project.secondary_sources) as s
      )

    -- To CodeBuild Project (edge)
    union all
    select
      repository.arn as from_id,
      cbproject.arn as to_id,
      null as id,
      'codebuild project' as title,
      'codecommit_repository_to_codebuild_project' as category,
      jsonb_build_object(
        'Account ID', cbproject.account_id
      ) as properties
    from
      repository
    left join aws_codebuild_project cbproject
      on repository.clone_url_http in (
        select source ->> 'Location' as "l" from aws_codebuild_project
        union all
        select s ->> 'Location' as "l" from aws_codebuild_project, jsonb_array_elements(aws_codebuild_project.secondary_sources) as s
      )

    -- To Codepipeline (node)
    union all
    select
      null as from_id,
      null as to_id,
      p.arn as id,
      p.title as title,
      'aws_codepipeline_pipeline' as category,
      jsonb_build_object(
        'ARN', p.arn,
        'Account ID', p.account_id,
        'Region', p.region 
      ) as properties
    from
      repository
      cross join aws_codepipeline_pipeline as p
    where p.stages is not null
    and repository.repository_name in (
      select jsonb_path_query(p.stages, '$[*].Actions[*].Configuration.RepositoryName')::text
    )

    -- To Codepipeline (edge)
    union all
    select
      repository.arn as from_id,
      p.arn as to_id,
      null as id,
      p.title as title,
      'aws_codepipeline_pipeline' as category,
      jsonb_build_object(
        'ARN', p.arn,
        'Account ID', p.account_id,
        'Region', p.region 
      ) as properties
    from
      repository
      cross join aws_codepipeline_pipeline as p
    where p.stages is not null
    and repository.repository_name in (
      select jsonb_path_query(p.stages, '$[*].Actions[*].Configuration.RepositoryName')::text
    )

  EOQ

  param "arn" {}
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