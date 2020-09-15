from setuptools import setup

setup(
    name='vim-mlflow',
    version='0.1',
    description='Vim plugin to explore the MLflow database just like the website, but in Vim!',
    author='Andy Ganse',
    author_email='andy@ganse.org',
    install_requires=[
        'mlflow',
    ],
)
