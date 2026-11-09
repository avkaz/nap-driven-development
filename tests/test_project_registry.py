"""Project cleanup tests use disposable Git repositories and NDD state only."""
from pathlib import Path
import os
import shutil
import subprocess
import unittest

from process_environment import child_environment
import test_installers


class ProjectRegistryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.installer = test_installers.InstallerTests()
        self.addCleanup(self.installer.doCleanups)
        self.installer.setUp()
        self.root = self.installer.root
        self.state = self.installer.registry_state
        self.project = self.root / 'project space Кириллица'
        self.git('init', '--quiet', '--template=', str(self.project))
        self.git('-C', str(self.project), 'config', 'ndd.prefix', 'ak')
        self.git('-C', str(self.project), 'config', 'example.keep', 'unchanged')

    def git(self, *args: str, success: bool = True) -> subprocess.CompletedProcess[str]:
        environment = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
        environment.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1')
        result = subprocess.run(['git', *args], capture_output=True, text=True,
                                env=environment, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def registry(self, action='register', *, project=None, prefix='ak', dry_run=False,
                 success=True, skill=None, answer=''):
        skill = skill or self.installer.distribution / 'skills/ndd-setup'
        if test_installers.POWERSHELL:
            command = [os.environ.get('NDD_TEST_POWERSHELL', 'powershell'), '-NoProfile',
                       '-ExecutionPolicy', 'Bypass', '-File', str(skill / 'scripts/project-registry.ps1'),
                       '-Action', action]
            if action == 'register':
                command += ['-Project', str(project or self.project), '-Prefix', prefix]
            if dry_run:
                command += ['-DryRun']
        else:
            command = ['/bin/bash', str(skill / 'scripts/project-registry.sh'), action]
            if action == 'register':
                command += ['--project', str(project or self.project), '--prefix', prefix]
            if dry_run:
                command += ['--dry-run']
        result = subprocess.run(command, capture_output=True, text=True, errors='replace',
                                input=answer, env=child_environment(command[0]), timeout=30)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def records(self):
        return list((self.state / 'projects').glob('*.record'))

    def link(self, path: Path, target: Path) -> None:
        if test_installers.WINDOWS:
            subprocess.run(['cmd', '/c', 'mklink', '/J', str(path), str(target)],
                           check=True, capture_output=True)
        else:
            path.symlink_to(target)

    def enable_private_specs(self, root: Path) -> Path:
        """Set up private specs the way ndd-setup does and return the spec file."""
        spec = root / 'ak-001-change' / 'spec.md'
        spec.parent.mkdir(parents=True)
        spec.write_text('private')
        self.git('-C', str(self.project), 'config', 'ndd.specsRoot', root.as_posix())
        exclude = self.project / '.git/info/exclude'
        exclude.parent.mkdir(exist_ok=True)
        exclude.write_text('*.log\n/ndd-specs\n')
        self.link(self.project / 'ndd-specs', root)
        return spec

    def test_private_specs_cleanup_keeps_folder_without_answer(self):
        private = self.state / 'specs' / 'project'
        spec = self.enable_private_specs(private)
        self.registry()
        before = test_installers.snapshot(self.root)
        result = self.registry('cleanup', dry_run=True)
        self.assertIn('will ask whether to delete private specs', result.stdout)
        self.assertEqual(test_installers.snapshot(self.root), before)
        result = self.registry('cleanup')
        self.assertIn('Kept private specs', result.stdout)
        self.assertEqual(spec.read_text(), 'private')
        self.assertFalse(os.path.lexists(self.project / 'ndd-specs'))
        self.assertEqual((self.project / '.git/info/exclude').read_text().split(), ['*.log'])
        result = self.git('-C', str(self.project), 'config', '--get', 'ndd.specsRoot', success=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.records(), [])

    def test_private_specs_and_worktree_links_deleted_after_confirmation(self):
        private = self.state / 'specs' / 'project'
        self.enable_private_specs(private)
        self.git('-C', str(self.project), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--quiet', '--allow-empty', '-m', 'test')
        worktree = self.root / 'linked worktree'
        self.git('-C', str(self.project), 'worktree', 'add', '--quiet', '--detach', str(worktree))
        self.link(worktree / 'ndd-specs', private)
        self.registry()
        result = self.registry('cleanup', answer='y\n')
        self.assertIn('Deleted private specs', result.stdout)
        self.assertFalse(os.path.lexists(worktree / 'ndd-specs'))
        self.assertFalse(os.path.lexists(self.project / 'ndd-specs'))
        self.assertFalse(self.state.exists())

    def test_private_specs_outside_state_are_never_deleted(self):
        private = self.root / 'elsewhere'
        spec = self.enable_private_specs(private)
        self.registry()
        result = self.registry('cleanup', answer='y\n')
        self.assertIn('retained record', result.stdout + result.stderr)
        self.assertEqual(spec.read_text(), 'private')
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.specsRoot').stdout.strip(),
                         private.as_posix())
        self.assertEqual(len(self.records()), 1)

    def test_registration_reuse_and_confirmed_prefix_update(self):
        self.registry()
        record, = self.records()
        original = record.read_bytes()
        modified = record.stat().st_mtime_ns
        self.registry()
        self.assertEqual(record.read_bytes(), original)
        self.assertEqual(record.stat().st_mtime_ns, modified)
        self.git('-C', str(self.project), 'config', 'ndd.prefix', 'iv')
        self.registry(prefix='iv')
        self.assertEqual(self.records(), [record])
        self.assertEqual(record.read_text().splitlines()[-2:], ['ndd.prefix', 'iv'])

    def test_unsaved_or_invalid_prefix_is_not_registered(self):
        for prefix in ('zz', 'x', 'BAD', 'a.*'):
            with self.subTest(prefix=prefix):
                self.registry(prefix=prefix, success=False)
                self.assertEqual(self.records(), [])

    def test_cleanup_preview_and_absent_registry_do_not_write(self):
        self.registry('cleanup', dry_run=True)
        self.assertFalse(self.state.exists())
        self.registry()
        before = test_installers.snapshot(self.root)
        self.registry('cleanup', dry_run=True)
        self.assertEqual(test_installers.snapshot(self.root), before)

    def test_cleanup_only_removes_registered_key_and_empty_state(self):
        self.registry()
        self.registry('cleanup')
        result = self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix', success=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'example.keep').stdout.strip(), 'unchanged')
        self.assertFalse(self.state.exists())
        self.registry('cleanup')
        self.assertFalse(self.state.exists())

    def test_missing_key_is_clean_and_other_state_is_preserved(self):
        self.registry()
        (self.state / 'unrelated.txt').write_text('keep')
        self.git('-C', str(self.project), 'config', '--unset-all', 'ndd.prefix')
        self.registry('cleanup')
        self.assertEqual((self.state / 'unrelated.txt').read_text(), 'keep')
        self.assertFalse((self.state / 'projects').exists())

    def test_changed_or_multiple_values_are_preserved_for_retry(self):
        self.registry()
        self.git('-C', str(self.project), 'config', 'ndd.prefix', 'iv')
        self.registry('cleanup')
        self.assertEqual(len(self.records()), 1)
        self.git('-C', str(self.project), 'config', 'ndd.prefix', 'ak')
        self.git('-C', str(self.project), 'config', '--add', 'ndd.prefix', '')
        self.registry('cleanup')
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get-all', 'ndd.prefix').stdout, 'ak\n\n')
        self.git('-C', str(self.project), 'config', '--replace-all', 'ndd.prefix', 'ak')
        self.registry('cleanup')

    def test_unavailable_project_does_not_block_uninstall(self):
        self.installer.run_installer('--codex-dir', str(self.installer.other))
        self.registry()
        moved = self.root / 'moved project'
        self.project.rename(moved)
        result = self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertIn('retained record', result.stdout)
        self.assertFalse((self.installer.target / 'ndd-setup').exists())
        self.assertFalse((self.installer.other / 'ndd-setup').exists())
        self.assertEqual(len(self.records()), 1)
        moved.rename(self.project)
        self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertFalse(self.state.exists())

    def test_git_write_failure_retains_record_and_retry_succeeds(self):
        self.registry()
        lock = self.project / '.git/config.lock'
        lock.write_text('busy')
        self.registry('cleanup')
        self.assertEqual(len(self.records()), 1)
        self.assertTrue(lock.exists())
        lock.unlink()
        self.registry('cleanup')

    def test_shared_registry_lock_blocks_registration_and_cleanup(self):
        self.registry()
        lock = self.state / '.projects.lock'
        lock.mkdir()
        before = test_installers.snapshot(self.root)
        self.registry(success=False)
        self.registry('cleanup', success=False)
        self.registry('cleanup', dry_run=True, success=False)
        self.assertEqual(test_installers.snapshot(self.root), before)

    def test_malformed_record_cannot_delete_another_key(self):
        self.registry()
        record, = self.records()
        record.write_text(record.read_text().replace('ndd.prefix', 'example.keep'))
        self.registry('cleanup')
        self.assertTrue(record.exists())
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix').stdout.strip(), 'ak')

    def test_partial_cleanup_keeps_only_unresolved_records(self):
        self.registry()
        other = self.root / 'second project'
        self.git('init', '--quiet', '--template=', str(other))
        self.git('-C', str(other), 'config', 'ndd.prefix', 'iv')
        self.registry(project=other, prefix='iv')
        self.git('-C', str(other), 'config', 'ndd.prefix', 'zz')
        self.registry('cleanup')
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix', success=False).returncode, 1)
        record, = self.records()
        self.assertIn('second project', record.read_text())
        self.git('-C', str(other), 'config', 'ndd.prefix', 'iv')
        self.registry('cleanup')

    def test_bad_record_does_not_prevent_cleaning_other_projects(self):
        self.registry()
        bad_record = self.state / 'projects/!invalid.record'
        bad_record.write_text('invalid')
        result = self.registry('cleanup')
        self.assertIn('retained record', result.stdout + result.stderr)
        self.assertEqual(bad_record.read_text(), 'invalid')
        self.assertEqual(self.records(), [bad_record])
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix', success=False).returncode, 1)

    def test_locked_registry_does_not_block_uninstall(self):
        self.installer.run_installer('--codex-dir', str(self.installer.other))
        self.registry()
        (self.state / '.projects.lock').mkdir()
        before = test_installers.snapshot(self.root)
        result = self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other), '--dry-run')
        self.assertIn('continuing NDD removal', result.stdout)
        self.assertEqual(test_installers.snapshot(self.root), before)
        registry_before = test_installers.snapshot(self.state)
        result = self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertIn('continuing NDD removal', result.stdout)
        self.assertFalse((self.installer.target / 'ndd-setup').exists())
        self.assertFalse((self.installer.other / 'ndd-setup').exists())
        self.assertEqual(test_installers.snapshot(self.state), registry_before)

    def test_missing_registry_helper_does_not_block_uninstall(self):
        self.installer.run_installer('--codex-dir', str(self.installer.other))
        self.registry()
        for suffix in ('sh', 'ps1'):
            (self.installer.distribution / f'skills/ndd-setup/scripts/project-registry.{suffix}').unlink()
        result = self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertIn('cleanup helper is missing', result.stdout)
        self.assertFalse((self.installer.target / 'ndd-setup').exists())
        self.assertFalse((self.installer.other / 'ndd-setup').exists())
        self.assertEqual(len(self.records()), 1)

    def test_included_config_is_never_changed(self):
        included = self.root / 'included.gitconfig'
        included.write_text('[ndd]\n\tprefix = other\n[example]\n\tkeep = included\n')
        self.git('-C', str(self.project), 'config', 'include.path', str(included))
        original = included.read_bytes()
        self.registry()
        self.registry('cleanup')
        self.assertEqual(included.read_bytes(), original)
        config = self.project / '.git/config'
        self.assertEqual(self.git('config', '--file', str(config), '--no-includes', '--get', 'ndd.prefix', success=False).returncode, 1)

    def test_registry_failure_does_not_block_source_clone_removal(self):
        self.installer.prepare_source_clone()
        self.installer.run_installer('--codex-dir', str(self.installer.other))
        self.registry()
        self.git('-C', str(self.project), 'config', 'ndd.prefix', 'iv')
        result = self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertIn('retained record', result.stdout)
        self.assertFalse(self.installer.distribution.exists())
        self.assertFalse((self.installer.target / 'ndd-setup').exists())
        self.assertFalse((self.installer.other / 'ndd-setup').exists())
        self.assertEqual(len(self.records()), 1)
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix').stdout.strip(), 'iv')

    def test_linked_worktrees_share_one_record_even_after_worktree_removal(self):
        self.git('-C', str(self.project), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                 'commit', '--quiet', '--allow-empty', '-m', 'test')
        worktree = self.root / 'linked worktree'
        self.git('-C', str(self.project), 'worktree', 'add', '--quiet', '--detach', str(worktree))
        self.registry(project=worktree)
        self.registry()
        self.assertEqual(len(self.records()), 1)
        self.git('-C', str(self.project), 'worktree', 'remove', str(worktree))
        self.registry('cleanup')
        self.assertFalse(self.state.exists())

    def test_installed_helper_survives_source_removal(self):
        self.installer.run_installer()
        shutil.rmtree(self.installer.distribution)
        self.registry(skill=self.installer.target / 'ndd-setup')
        self.registry('cleanup', skill=self.installer.target / 'ndd-setup')

    def test_one_agent_keeps_registry_and_full_uninstall_cleans_it(self):
        self.installer.run_installer('--codex-dir', str(self.installer.other))
        self.registry()
        self.installer.run_installer('--uninstall')
        self.assertEqual(len(self.records()), 1)
        self.assertEqual(self.git('-C', str(self.project), 'config', '--get', 'ndd.prefix').stdout.strip(), 'ak')
        before = test_installers.snapshot(self.root)
        self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other), '--dry-run')
        self.assertEqual(test_installers.snapshot(self.root), before)
        self.installer.run_installer('--uninstall', '--codex-dir', str(self.installer.other))
        self.assertFalse(self.state.exists())

    @unittest.skipIf(test_installers.WINDOWS, 'POSIX symlink creation')
    def test_redirected_registry_record_or_git_config_is_rejected(self):
        self.registry()
        record, = self.records()
        original = record.read_bytes()
        outside = self.root / 'foreign-record'
        record.rename(outside)
        record.symlink_to(outside)
        self.registry('cleanup')
        self.assertEqual(outside.read_bytes(), original)
        record.unlink()
        outside.rename(record)
        config = self.project / '.git/config'
        outside_config = self.root / 'foreign-config'
        config.rename(outside_config)
        original = outside_config.read_bytes()
        config.symlink_to(outside_config)
        self.registry('cleanup')
        self.assertEqual(outside_config.read_bytes(), original)
