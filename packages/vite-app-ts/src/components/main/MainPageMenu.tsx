import { Menu } from 'antd';
import React, { FC } from 'react';
import { Link } from 'react-router-dom';

export interface IMainPageMenuProps {
  route: string;
  setRoute: React.Dispatch<React.SetStateAction<string>>;
}

export const MainPageMenu: FC<IMainPageMenuProps> = (props) => (
  <Menu
    style={{
      textAlign: 'center',
    }}
    selectedKeys={[props.route]}
    mode="horizontal">
    <Menu.Item key="/">
      <Link
        onClick={(): void => {
          props.setRoute('/');
        }}
        to="/">
        Main
      </Link>
    </Menu.Item>
    <Menu.Item key="/lend">
      <Link
        onClick={(): void => {
          props.setRoute('/lend');
        }}
        to="/lend">
        Lend
      </Link>
    </Menu.Item>
    <Menu.Item key="/borrow">
      <Link
        onClick={(): void => {
          props.setRoute('/borrow');
        }}
        to="/borrow">
        Borrow
      </Link>
    </Menu.Item>
    <Menu.Item key="/your-contract">
      <Link
        onClick={(): void => {
          props.setRoute('/your-contract');
        }}
        to="/your-contract">
        Debug: Your Contract
      </Link>
    </Menu.Item>
    <Menu.Item key="/price-oracle-nft">
      <Link
        onClick={(): void => {
          props.setRoute('/price-oracle-nft');
        }}
        to="/price-oracle-nft">
        Debug: Price Oracle NFT
      </Link>
    </Menu.Item>
  </Menu>
);
