#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    skipDefaultCheckout()  // see 'Checkout SCM' below, once perms are fixed this is no longer needed
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
        sh 'git fetch' // to pull the tags
      }
    }

    stage('Validate') {
      parallel {
        stage('Changelog') {
          steps { sh 'ci/parse-changelog' }
        }
      }
    }

    stage('Build Docker image') {
      steps {
        sh './build.sh -j'
      }
    }

    stage('Run Tests') {
      parallel {
        stage('Kubernetes 1.7 in GKE') {
          steps { sh 'cd ci/authn-k8s && summon ./test.sh gke' }
        }
      }
      post {
        always {
          junit 'spec/reports/*.xml,spec/reports-audit/*.xml,cucumber/api/features/reports/**/*.xml,cucumber/policy/features/reports/**/*.xml,cucumber/authenticators/features/reports/**/*.xml'
          publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false])
        }
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
